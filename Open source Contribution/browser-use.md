The browser use supports a set of providers:

  - OpenAI, Azure OpenAI
  - Anthropic, AWS Bedrock
  - Google Gemini
  - Groq, DeepSeek, Cerebras
  - Mistral, Ollama, OpenRouter, Vercel
  - Browser Use's own models

I have three options -
- Pay and use from any of the paid providers above (drains money like crazy)
- Use Ollama (can't afford super expensive GPUs)
- Customize with glm coding plan with its openai compatible api

Zhipu AI's GLM API provides OpenAI-compatible endpoints. We can customize  ChatOpenAI with a custom base URL:

```python
llm = ChatOpenAI(
	model = 'glm-4.7',
	api_key = '<api-key>',
	base_url = 'https://api.z.ai/api/coding/paas/v4'
)
```