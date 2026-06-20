# Pi Extensions

This directory contains custom extensions for the Pi coding agent.

## Available Extensions

### ollama-models.ts

**Ollama Models Extension** - Provides access to both local and cloud Ollama models.

#### Features
- Automatically detects available models from Ollama server
- Supports both local and cloud models
- Auto-detects model capabilities (vision, reasoning, tools)
- Detects context window size and max tokens
- Provides `/ollama-models` command to list available models

#### Usage

1. **Enable the extension:**
   ```bash
   pi -e ~/.pi/agent/extensions/ollama-models.ts
   ```

2. **List available models:**
   ```bash
   pi /ollama-models
   ```

3. **Use a specific model:**
   ```bash
   pi --model ollama/llama3.2:latest "Your prompt here"
   ```

#### Configuration

- `OLAMA_BASE_URL` - Override default Ollama server URL (default: `http://localhost:11434`)
- `OLAMA_API_KEY` - API key if your server requires authentication

#### Example Output

```
Found 8 Ollama model(s):

📦 Local Models:
  • gemma3:latest (gemma3, 8.2K context)
  • embeddinggemma:latest (gemma3, 2.0K context)
  • gemma:latest (gemma, 8.2K context)
  • gemma2:latest (gemma2, 8.2K context)
  • llama2-uncensored:latest (llama, 2.0K context)
  • mistral:latest (llama, 32.8K context)
  • llama3.2:latest (llama, 131.1K context)

☁️ Cloud Models:
  • minimax-m2.5:cloud (cloud, 202.8K context) 🧠
```

#### Installation

1. Copy the extension to your Pi extensions directory:
   ```bash
   mkdir -p ~/.pi/agent/extensions
   cp ollama-models.ts ~/.pi/agent/extensions/
   ```

2. Enable it in your Pi session or add it to your configuration.

#### Requirements
- Ollama server running (local or remote)
- Node.js 18+ (for Pi coding agent)
