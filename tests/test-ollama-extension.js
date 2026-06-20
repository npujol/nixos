// Simple test script to verify the Ollama extension
const { createAgentSession } = require('@earendil-works/pi-coding-agent');

async function test() {
  try {
    const session = createAgentSession({
      extensions: ['/home/nainai/projects/nix-config/home/nainai/pi-extensions/ollama-models.ts'],
      model: 'ollama/llama3.2:latest'
    });

    const result = await session.sendUserMessage('Hello, tell me about yourself in one sentence.');
    console.log('Response:', result);
  } catch (error) {
    console.error('Error:', error.message);
  }
}

test();