/**
 * Llama.cpp Provider Extension
 *
 * Provides access to llama.cpp models via its OpenAI-compatible API.
 * Automatically detects model features from the server.
 *
 * Usage:
 *   1. Start llama.cpp server: ./llama-server -m model.gguf --port 8080
 *   2. Enable extension: pi -e ~/.pi/agent/extensions/llama-cpp.ts
 *   3. Select model from /model menu
 *
 * Configuration:
 *   Set LLAMA_CPP_BASE_URL env var to override default (http://localhost:8080/v1)
 *   Set LLAMA_CPP_API_KEY if your server requires authentication
 *
 * Features:
 *   - Automatic model detection from llama.cpp server
 *   - Auto-detects model capabilities (vision, reasoning)
 *   - Supports text and vision models (LLaVA, Moondream, etc.)
 *   - Detects context window size and max tokens
 *   - Fallback configuration when server is not running
 *
 * Alternative: Use ~/.pi/agent/models.json for static configuration:
 *   {
 *     "providers": {
 *       "llama-cpp": {
 *         "baseUrl": "http://localhost:8080/v1",
 *         "api": "openai-completions",
 *         "apiKey": "none",
 *         "models": [
 *           {
 *             "id": "local-model",
 *             "name": "Local Model",
 *             "reasoning": false,
 *             "input": ["text"],
 *             "contextWindow": 8192,
 *             "maxTokens": 4096,
 *             "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
 *           }
 *         ]
 *       }
 *     }
 *   }
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// =============================================================================
// Constants
// =============================================================================

const DEFAULT_BASE_URL = "http://localhost:8080/v1";
const DEFAULT_CONTEXT_WINDOW = 8192;
const DEFAULT_MAX_TOKENS = 4096;

// =============================================================================
// Types
// =============================================================================

interface LlamaCppModelInfo {
	id: string;
	object?: string;
	owned_by?: string;
	meta?: {
		context_length?: number;
		max_tokens?: number;
		capabilities?: string[];
	};
}

interface LlamaCppModelsResponse {
	object: string;
	data: LlamaCppModelInfo[];
}

// =============================================================================
// Model Detection
// =============================================================================

/**
 * Detect available models and their capabilities from llama.cpp server
 */
async function detectModels(baseUrl: string, apiKey?: string): Promise<any[]> {
	try {
		const headers: Record<string, string> = {
			"Content-Type": "application/json",
		};

		if (apiKey) {
			headers["Authorization"] = `Bearer ${apiKey}`;
		}

		// Add timeout to prevent hanging when server is not running
		const controller = new AbortController();
		const timeoutId = setTimeout(() => controller.abort(), 3000); // 3 second timeout

		const response = await fetch(`${baseUrl}/models`, {
			method: "GET",
			headers,
			signal: controller.signal,
		}).finally(() => clearTimeout(timeoutId));

		if (!response.ok) {
			console.warn(`llama.cpp: Failed to detect models: ${response.status} ${response.statusText}`);
			return [];
		}

		const data = (await response.json()) as LlamaCppModelsResponse;

		if (!data.data || !Array.isArray(data.data)) {
			console.warn("llama.cpp: Invalid response from /models endpoint");
			return [];
		}

		// Convert llama.cpp model info to pi model config
		return data.data.map((model) => {
			const contextWindow = model.meta?.n_ctx_train || model.meta?.context_length || DEFAULT_CONTEXT_WINDOW;
			const maxTokens = model.meta?.max_tokens || Math.min(DEFAULT_MAX_TOKENS, Math.floor(contextWindow / 2));

			// Detect if model supports vision based on capabilities or model name
			const capabilities = model.meta?.capabilities || [];
			const supportsVision =
				capabilities.includes("vision") ||
				capabilities.includes("image") ||
				model.id.toLowerCase().includes("vision") ||
				model.id.toLowerCase().includes("llava") ||
				model.id.toLowerCase().includes("bakllava") ||
				model.id.toLowerCase().includes("moondream");

			// Detect reasoning/thinking models
			const supportsReasoning =
				capabilities.includes("reasoning") ||
				model.id.toLowerCase().includes("qwq") ||
				model.id.toLowerCase().includes("deepseek-r1") ||
				model.id.toLowerCase().includes("thinking");

			return {
				id: model.id,
				name: model.id.split("/").pop() || model.id, // Use last part of path as display name
				reasoning: supportsReasoning,
				input: supportsVision ? (["text", "image"] as const) : (["text"] as const),
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow,
				maxTokens,
				compat: {
					// llama.cpp doesn't support all OpenAI features
					supportsDeveloperRole: false,
					supportsReasoningEffort: false,
					supportsUsageInStreaming: true, // llama.cpp supports this
					maxTokensField: "max_tokens" as const,
				},
			};
		});
	} catch (error) {
		// Handle network errors gracefully (ECONNREFUSED, timeout, etc.)
		if (error instanceof Error) {
			if (error.name === 'AbortError') {
				console.warn("llama.cpp: Connection timeout - server may not be running");
			} else {
				console.warn(`llama.cpp: Could not connect to server: ${error.message}`);
			}
		} else {
			console.warn("llama.cpp: Error detecting models:", error);
		}
		return [];
	}
}

/**
 * Get fallback model configuration when detection fails or no models are running
 */
function getFallbackModels(): any[] {
	return [
		{
			id: "local-model",
			name: "Local Model (llama.cpp)",
			reasoning: false,
			input: ["text"] as const,
			cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
			contextWindow: DEFAULT_CONTEXT_WINDOW,
			maxTokens: DEFAULT_MAX_TOKENS,
			compat: {
				supportsDeveloperRole: false,
				supportsReasoningEffort: false,
				supportsUsageInStreaming: true,
				maxTokensField: "max_tokens" as const,
			},
		},
	];
}

// =============================================================================
// Extension Entry Point
// =============================================================================

export default async function (pi: ExtensionAPI) {
	// Get configuration from environment or use defaults
	const baseUrl = process.env.LLAMA_CPP_BASE_URL || DEFAULT_BASE_URL;
	const apiKey = process.env.LLAMA_CPP_API_KEY;

	// Attempt to detect models from the server
	let models = await detectModels(baseUrl, apiKey);

	// Fall back to generic model if detection fails
	if (models.length === 0) {
		console.log("llama.cpp: No models detected, using fallback configuration");
		console.log(`llama.cpp: Make sure server is running at ${baseUrl}`);
		models = getFallbackModels();
	} else {
		console.log(`llama.cpp: Detected ${models.length} model(s)`);
	}

	// Register the provider
	pi.registerProvider("llama-cpp", {
		baseUrl,
		apiKey: apiKey || "none", // llama.cpp doesn't require API key by default
		api: "openai-completions",
		models,
	});
}
