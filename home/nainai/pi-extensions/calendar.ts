/**
 * Create macOS Calendar events and Reminders tasks from pi.
 *
 * Notifications are delivered by Calendar.app / Reminders.app themselves
 * (alarm on the event, remind-me date on the task), so they fire even after
 * pi has exited. Uses osascript; first use triggers a macOS permission prompt.
 */

import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";

const OSASCRIPT_TIMEOUT_MS = 60_000;

const EVENT_SCRIPT = `
on run argv
	set calName to item 1 of argv
	set ttl to item 2 of argv
	set notes to item 3 of argv
	set startParts to {item 4 of argv, item 5 of argv, item 6 of argv, item 7 of argv, item 8 of argv}
	set durMin to (item 9 of argv) as integer
	set alarmMin to (item 10 of argv) as integer
	set sd to my mkDate(startParts)
	set ed to sd + durMin * minutes
	tell application "Calendar"
		if calName is "" then
			set cal to first calendar whose writable is true
		else
			set cal to calendar calName
		end if
		tell cal
			set ev to make new event with properties {summary:ttl, description:notes, start date:sd, end date:ed}
			tell ev
				make new display alarm at end of display alarms with properties {trigger interval:(-alarmMin)}
			end tell
		end tell
		return (name of cal) & " | " & (uid of ev)
	end tell
end run

on mkDate(p)
	set d to current date
	set day of d to 1
	set year of d to (item 1 of p) as integer
	set month of d to (item 2 of p) as integer
	set day of d to (item 3 of p) as integer
	set hours of d to (item 4 of p) as integer
	set minutes of d to (item 5 of p) as integer
	set seconds of d to 0
	return d
end mkDate
`;

const REMINDER_SCRIPT = `
on run argv
	set listName to item 1 of argv
	set ttl to item 2 of argv
	set notes to item 3 of argv
	set p to {item 4 of argv, item 5 of argv, item 6 of argv, item 7 of argv, item 8 of argv}
	set dd to my mkDate(p)
	tell application "Reminders"
		if listName is "" then
			set lst to default list
		else
			set lst to list listName
		end if
		set r to make new reminder at end of reminders of lst with properties {name:ttl, body:notes, due date:dd, remind me date:dd}
		return (name of lst) & " | " & (id of r)
	end tell
end run

on mkDate(p)
	set d to current date
	set day of d to 1
	set year of d to (item 1 of p) as integer
	set month of d to (item 2 of p) as integer
	set day of d to (item 3 of p) as integer
	set hours of d to (item 4 of p) as integer
	set minutes of d to (item 5 of p) as integer
	set seconds of d to 0
	return d
end mkDate
`;

const LIST_SCRIPT = `
tell application "Calendar" to set cals to name of every calendar whose writable is true
tell application "Reminders" to set lsts to name of every list
return "calendars: " & (cals as string) & linefeed & "reminder lists: " & (lsts as string)
`;

const REMINDER_UPDATE_SCRIPT = `
on run argv
	set rid to item 1 of argv
	set ttl to item 2 of argv
	set notes to item 3 of argv
	set hasDue to (item 4 of argv) is "1"
	set done to item 10 of argv
	tell application "Reminders"
		set r to reminder id rid
		if ttl is not "" then set name of r to ttl
		if notes is not "" then set body of r to notes
		if hasDue then
			set dd to my mkDate({item 5 of argv, item 6 of argv, item 7 of argv, item 8 of argv, item 9 of argv})
			set due date of r to dd
			set remind me date of r to dd
		end if
		if done is "true" then set completed of r to true
		if done is "false" then set completed of r to false
		return (name of r) & " | " & (due date of r as string)
	end tell
end run

on mkDate(p)
	set d to current date
	set day of d to 1
	set year of d to (item 1 of p) as integer
	set month of d to (item 2 of p) as integer
	set day of d to (item 3 of p) as integer
	set hours of d to (item 4 of p) as integer
	set minutes of d to (item 5 of p) as integer
	set seconds of d to 0
	return d
end mkDate
`;

const REMINDER_DELETE_SCRIPT = `
on run argv
	tell application "Reminders"
		set r to reminder id (item 1 of argv)
		set n to name of r
		delete r
		return n
	end tell
end run
`;

const REMINDER_LIST_SCRIPT = `
on run argv
	set listName to item 1 of argv
	set out to {}
	tell application "Reminders"
		if listName is "" then
			set lst to default list
		else
			set lst to list listName
		end if
		repeat with r in (reminders of lst whose completed is false)
			set dd to "none"
			if due date of r is not missing value then set dd to (due date of r as string)
			set end of out to (id of r) & " | " & (name of r) & " | due " & dd
		end repeat
	end tell
	set AppleScript's text item delimiters to linefeed
	return out as string
end run
`;

function runOsascript(script: string, args: string[], signal?: AbortSignal): Promise<string> {
	return new Promise((resolve, reject) => {
		execFile(
			"osascript",
			["-e", script, ...args],
			{ timeout: OSASCRIPT_TIMEOUT_MS, signal },
			(error, stdout, stderr) => {
				if (error) {
					reject(new Error((stderr || error.message).trim()));
					return;
				}
				resolve(stdout.trim());
			},
		);
	});
}

function pad(n: number): string {
	return String(n).padStart(2, "0");
}

// Naive local-time parts: AppleScript's `current date` is already in the system timezone.
function skipWeekend(d: Date, allowWeekend: boolean | undefined): Date {
	if (allowWeekend) {
		return d;
	}
	const shift = d.getDay() === 6 ? 2 : d.getDay() === 0 ? 1 : 0;
	return new Date(d.getFullYear(), d.getMonth(), d.getDate() + shift, d.getHours(), d.getMinutes());
}

function resolveWhen(when: string | undefined, afterHours: number | undefined, allowWeekend?: boolean): Date {
	return skipWeekend(resolveRaw(when, afterHours), allowWeekend);
}

function resolveRaw(when: string | undefined, afterHours: number | undefined): Date {
	if (afterHours !== undefined) {
		return new Date(Date.now() + afterHours * 3_600_000);
	}
	if (!when) {
		throw new Error("Provide `when` (YYYY-MM-DDTHH:MM, local time) or `afterHours`.");
	}
	const m = /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})$/.exec(when.trim());
	if (!m) {
		throw new Error(`Invalid \`when\` "${when}". Expected YYYY-MM-DDTHH:MM (local time).`);
	}
	const [, y, mo, d, h, mi] = m.map(Number);
	const date = new Date(y, mo - 1, d, h, mi);
	if (Number.isNaN(date.getTime())) {
		throw new Error(`Invalid date "${when}".`);
	}
	return date;
}

function dateParts(d: Date): string[] {
	return [d.getFullYear(), d.getMonth() + 1, d.getDate(), d.getHours(), d.getMinutes()].map(String);
}

function formatLocal(d: Date): string {
	return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

const whenFields = {
	when: Type.Optional(Type.String({ description: "Local time, YYYY-MM-DDTHH:MM. Ignored if afterHours is set." })),
	afterHours: Type.Optional(Type.Number({ description: "Relative: hours from now (e.g. 48)." })),
	allowWeekend: Type.Optional(
		Type.Boolean({ description: "Default false: a Saturday/Sunday result moves to Monday, same time." }),
	),
};

const calendarEventTool = defineTool({
	name: "calendar_event",
	label: "Calendar event",
	description:
		"Create an event in macOS Calendar with a notification alarm. Use for time-bound items (meetings, checks at a time).",
	parameters: Type.Object({
		title: Type.String(),
		...whenFields,
		durationMinutes: Type.Optional(Type.Number({ description: "Default 30." })),
		alarmMinutesBefore: Type.Optional(Type.Number({ description: "Notify N minutes before start. Default 0 (at start)." })),
		notes: Type.Optional(Type.String()),
		calendar: Type.Optional(Type.String({ description: "Calendar name. Default: first writable calendar." })),
	}),

	async execute(_id, p, signal) {
		const start = resolveWhen(p.when, p.afterHours, p.allowWeekend);
		const result = await runOsascript(
			EVENT_SCRIPT,
			[
				p.calendar ?? "",
				p.title,
				p.notes ?? "",
				...dateParts(start),
				String(p.durationMinutes ?? 30),
				String(p.alarmMinutesBefore ?? 0),
			],
			signal,
		);
		return {
			content: [{ type: "text", text: `Event "${p.title}" created at ${formatLocal(start)} (${result})` }],
			details: { start: start.toISOString(), result },
		};
	},
});

const reminderTool = defineTool({
	name: "reminder_task",
	label: "Reminder task",
	description:
		"Create a task in macOS Reminders with a due date and a notification at that time. Use for to-dos / follow-ups.",
	parameters: Type.Object({
		title: Type.String(),
		...whenFields,
		notes: Type.Optional(Type.String()),
		list: Type.Optional(Type.String({ description: "Reminders list name. Default list if omitted." })),
	}),

	async execute(_id, p, signal) {
		const due = resolveWhen(p.when, p.afterHours, p.allowWeekend);
		const result = await runOsascript(
			REMINDER_SCRIPT,
			[p.list ?? "", p.title, p.notes ?? "", ...dateParts(due)],
			signal,
		);
		return {
			content: [{ type: "text", text: `Reminder "${p.title}" due ${formatLocal(due)} (${result})` }],
			details: { due: due.toISOString(), result },
		};
	},
});

const listTargetsTool = defineTool({
	name: "calendar_targets",
	label: "Calendar targets",
	description: "List writable calendars and Reminders lists available for calendar_event / reminder_task.",
	parameters: Type.Object({}),
	async execute(_id, _p, signal) {
		const text = await runOsascript(LIST_SCRIPT, [], signal);
		return { content: [{ type: "text", text }], details: {} };
	},
});

const reminderUpdateTool = defineTool({
	name: "reminder_update",
	label: "Reminder update",
	description:
		"Update a Reminders task by id (as returned by reminder_task / reminder_list). Only given fields change.",
	parameters: Type.Object({
		id: Type.String(),
		title: Type.Optional(Type.String()),
		notes: Type.Optional(Type.String()),
		...whenFields,
		completed: Type.Optional(Type.Boolean()),
	}),

	async execute(_id, p, signal) {
		const hasDue = p.when !== undefined || p.afterHours !== undefined;
		const due = hasDue ? resolveWhen(p.when, p.afterHours, p.allowWeekend) : undefined;
		const result = await runOsascript(
			REMINDER_UPDATE_SCRIPT,
			[
				p.id,
				p.title ?? "",
				p.notes ?? "",
				hasDue ? "1" : "0",
				...(due ? dateParts(due) : ["", "", "", "", ""]),
				p.completed === undefined ? "" : String(p.completed),
			],
			signal,
		);
		return { content: [{ type: "text", text: `Reminder updated: ${result}` }], details: { result } };
	},
});

const reminderDeleteTool = defineTool({
	name: "reminder_delete",
	label: "Reminder delete",
	description: "Delete a Reminders task by id (as returned by reminder_task / reminder_list).",
	parameters: Type.Object({ id: Type.String() }),
	async execute(_id, p, signal) {
		const name = await runOsascript(REMINDER_DELETE_SCRIPT, [p.id], signal);
		return { content: [{ type: "text", text: `Reminder deleted: ${name}` }], details: { name } };
	},
});

const reminderListTool = defineTool({
	name: "reminder_list",
	label: "Reminder list",
	description: "List open (not completed) Reminders tasks with their ids and due dates.",
	parameters: Type.Object({
		list: Type.Optional(Type.String({ description: "Reminders list name. Default list if omitted." })),
	}),
	async execute(_id, p, signal) {
		const text = await runOsascript(REMINDER_LIST_SCRIPT, [p.list ?? ""], signal);
		return { content: [{ type: "text", text: text || "(no open reminders)" }], details: {} };
	},
});

export default function calendarExtension(pi: ExtensionAPI) {
	if (process.platform !== "darwin") {
		return;
	}
	pi.registerTool(calendarEventTool);
	pi.registerTool(reminderTool);
	pi.registerTool(listTargetsTool);
	pi.registerTool(reminderUpdateTool);
	pi.registerTool(reminderDeleteTool);
	pi.registerTool(reminderListTool);
}
