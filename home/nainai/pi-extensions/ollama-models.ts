/**
 * Ollama Models Extension
 * 
 * Provides access to both local and cloud Ollama models.
 * Automatically detects available models from the Ollama server.
 * 
 * Usage:
 *   1. Start Ollama server
 *   2. Enable extension: pi -e ~/.pi/agent/extensions/ollama-models.ts
 *   3. Select model from /model menu
 *
 * Configuration:
 *   Set OLAMA_BASE_URL env var to override default (http://localhost:11434)
 *   Set OLAMA_API_KEY if your server requires authentication
 *
 * Features:
 *   - Automatic detection of local and cloud models from Ollama server
 *   - Auto-detects model capabilities (vision, reasoning, tools)
 *   - Detects context window size and max tokens
 *   - Fallback configuration when server is not running
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// =============================================================================
// Constants
// =============================================================================

const DEFAULT_BASE_URL = "http://localhost:11434";
const OPENAI_API_BASE_URL = "http://localhost:11434/v1";
const OLAMA_CLOUD_REGISTRY = "https://ollama.com/api/tags";
const DEFAULT_CONTEXT_WINDOW = 8192;
const DEFAULT_MAX_TOKENS = 4096;

// =============================================================================
// Types
// =============================================================================

interface OllamaModelInfo {
    name: string;
    model: string;
    modified_at: string;
    size: number;
    digest: string;
    details?: {
        parent_model?: string;
        format?: string;
        family?: string;
        families?: string[] | null;
        parameter_size?: string;
        quantization_level?: string;
        context_length?: number;
        embedding_length?: number;
    };
    capabilities?: string[];
    remote_host?: string;
    remote_model?: string;
}

interface OllamaModelsResponse {
    models: OllamaModelInfo[];
}

// =============================================================================
// Model Detection
// =============================================================================

/**
 * Detect available models from both local Ollama server and cloud registry
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

        // Fetch local models
        const localResponse = await fetch(`${baseUrl}/api/tags`, {
            method: "GET",
            headers,
            signal: controller.signal,
        });

        if (!localResponse.ok) {
            console.warn(`Ollama: Failed to detect local models: ${localResponse.status} ${localResponse.statusText}`);
            // Continue to try cloud models
        }

        const localData = localResponse.ok ? (await localResponse.json()) as OllamaModelsResponse : { models: [] };

        if (!localData.models || !Array.isArray(localData.models)) {
            console.warn("Ollama: Invalid response from local /api/tags endpoint");
            return [];
        }

        // Fetch cloud models from official registry
        let cloudModels: OllamaModelInfo[] = [];
        try {
            const cloudResponse = await fetch(OLAMA_CLOUD_REGISTRY, {
                method: "GET",
                headers: {
                    "Content-Type": "application/json",
                },
                signal: controller.signal,
            });

            if (cloudResponse.ok) {
                const cloudData = (await cloudResponse.json()) as OllamaModelsResponse;
                if (cloudData.models && Array.isArray(cloudData.models)) {
                    cloudModels = cloudData.models;
                }
            }
        } catch (cloudError) {
            console.warn("Ollama: Could not fetch cloud models:", cloudError instanceof Error ? cloudError.message : cloudError);
        }

        // Combine local and cloud models, removing duplicates
        const allModels = [...localData.models, ...cloudModels];
        const uniqueModels = Array.from(new Map(allModels.map(model => [model.name, model]))).map(([_, model]) => model);

        // Convert Ollama model info to pi model config
        const validModels: any[] = [];
        
        for (const model of uniqueModels) {
            try {
                // Skip models without proper names
                if (!model.name) continue;

                const contextWindow = model.details?.context_length || DEFAULT_CONTEXT_WINDOW;
                const maxTokens = Math.min(DEFAULT_MAX_TOKENS, Math.floor(contextWindow / 2));

                // Detect if model supports vision based on capabilities or model name
                const capabilities = model.capabilities || [];
                const supportsVision = 
                    capabilities.includes("vision") ||
                    capabilities.includes("image") ||
                    model.name.toLowerCase().includes("vision") ||
                    model.name.toLowerCase().includes("llava") ||
                    model.name.toLowerCase().includes("bakllava");

                // Detect reasoning/thinking models
                const supportsReasoning = 
                    capabilities.includes("reasoning") ||
                    capabilities.includes("thinking") ||
                    model.name.toLowerCase().includes("qwq") ||
                    model.name.toLowerCase().includes("deepseek-r1");

                // Detect tools support
                const supportsTools = capabilities.includes("tools");

                // Determine if this is a cloud model
                // Cloud models either have remote_host set OR come from cloud registry with size 0
                const isCloudModel = !!model.remote_host || (model.size === 0 && !localData.models.some(localModel => localModel.name === model.name));
                const modelType = isCloudModel ? "cloud" : "local";
                const displayName = isCloudModel ? 
                    `${model.name} (cloud)` : 
                    model.name.split(":")[0]; // Remove tag for display

                validModels.push({
                    id: model.name,
                    name: model.name, // Use full model name as both ID and display name
                    reasoning: supportsReasoning,
                    input: supportsVision ? (["text", "image"] as const) : (["text"] as const),
                    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
                    contextWindow,
                    maxTokens,
                    compat: {
                        supportsDeveloperRole: false,
                        supportsReasoningEffort: supportsReasoning,
                        supportsUsageInStreaming: true,
                        maxTokensField: "max_tokens" as const,
                    },
                    metadata: {
                        type: modelType,
                        family: model.details?.family,
                        parameterSize: model.details?.parameter_size,
                        quantization: model.details?.quantization_level,
                        displayName: displayName, // Store display name in metadata
                        ...(isCloudModel && { 
                            remoteHost: model.remote_host,
                            remoteModel: model.remote_model 
                        })
                    }
                });
            } catch (error) {
                console.warn(`Ollama: Failed to process model ${model.name}:`, error instanceof Error ? error.message : error);
            }
        }

        return validModels;
    } catch (error) {
        // Handle network errors gracefully (ECONNREFUSED, timeout, etc.)
        if (error instanceof Error) {
            if (error.name === 'AbortError') {
                console.warn("Ollama: Connection timeout - server may not be running");
            } else {
                console.warn(`Ollama: Could not connect to server: ${error.message}`);
            }
        } else {
            console.warn("Ollama: Error detecting models:", error);
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
            id: "ollama-local",
            name: "Ollama Local Model (fallback)",
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
            metadata: {
                type: "local",
                fallback: true
            }
        },
        {
            id: "ollama-cloud",
            name: "Ollama Cloud Model (fallback)",
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
            metadata: {
                type: "cloud",
                fallback: true
            }
        }
    ];
}

// =============================================================================
// Extension Entry Point
// =============================================================================

export default async function (pi: ExtensionAPI) {
    
    // Register command to list Ollama models
    pi.registerCommand("ollama-models", {
        description: "List available Ollama models",
        handler: async (_args, ctx) => {
            const baseUrl = process.env.OLAMA_BASE_URL || DEFAULT_BASE_URL;
            const apiKey = process.env.OLAMA_API_KEY;
            
            ctx.ui.notify("Fetching Ollama models...", "info");
            
            try {
                const models = await detectModels(baseUrl, apiKey);
                
                if (models.length === 0) {
                    ctx.ui.notify("No Ollama models found", "warning");
                    return;
                }
                
                let message = `Found ${models.length} Ollama model(s):\n\n`;
                
                // Group by type
                const localModels = models.filter(m => m.metadata?.type === "local");
                const cloudModels = models.filter(m => m.metadata?.type === "cloud");
                
                if (localModels.length > 0) {
                    message += "📦 Local Models:\n";
                    localModels.forEach(model => {
                        const displayName = model.metadata?.displayName || model.name;
                        const family = model.metadata?.family || "unknown";
                        const context = (model.contextWindow / 1024).toFixed(1) + "K";
                        message += `  • ${displayName} (${family}, ${context} context)`;
                        if (model.reasoning) message += " 🧠";
                        if (model.input.includes("image")) message += " 🖼️";
                        message += "\n";
                    });
                    message += "\n";
                }
                
                if (cloudModels.length > 0) {
                    message += "☁️ Cloud Models:\n";
                    cloudModels.forEach(model => {
                        const displayName = model.metadata?.displayName || model.name;
                        const family = model.metadata?.family || "unknown";
                        const context = (model.contextWindow / 1024).toFixed(1) + "K";
                        message += `  • ${displayName} (${family}, ${context} context)`;
                        if (model.reasoning) message += " 🧠";
                        if (model.input.includes("image")) message += " 🖼️";
                        message += "\n";
                    });
                }
                
                ctx.ui.notify(message, "info");
                
            } catch (error) {
                ctx.ui.notify(`Failed to fetch Ollama models: ${error instanceof Error ? error.message : String(error)}`, "error");
            }
        }
    });
    // Get configuration from environment or use defaults
    const baseUrl = process.env.OLAMA_BASE_URL || DEFAULT_BASE_URL;
    const apiKey = process.env.OLAMA_API_KEY;

    // Attempt to detect models from the server
    let models = await detectModels(baseUrl, apiKey);

    // Fall back to generic models if detection fails
    if (models.length === 0) {
        console.log("Ollama: No models detected, using fallback configuration");
        console.log(`Ollama: Make sure server is running at ${baseUrl}`);
        models = getFallbackModels();
    } else {
        console.log(`Ollama: Detected ${models.length} model(s)`);
        
        // Log model details
        models.forEach(model => {
            const type = model.metadata?.type || "unknown";
            const family = model.metadata?.family || "unknown";
            console.log(`  - ${model.name} (${type}, ${family})`);
        });
    }

    // Separate local and cloud models
    const localModels = models.filter(model => model.metadata?.type !== "cloud");
    const cloudModels = models.filter(model => model.metadata?.type === "cloud");

    // Register local models with the main ollama provider
    if (localModels.length > 0) {
        pi.registerProvider("ollama", {
            baseUrl: OPENAI_API_BASE_URL,
            apiKey: apiKey || "none", // Ollama doesn't require API key by default
            api: "openai-completions",
            models: localModels,
        });
    }

    // Register cloud models with a separate provider if any exist
    if (cloudModels.length > 0) {
        pi.registerProvider("ollama-cloud", {
            baseUrl: OPENAI_API_BASE_URL,
            apiKey: apiKey || "none", // Ollama doesn't require API key by default
            api: "openai-completions",
            models: cloudModels,
        });
    }
}
