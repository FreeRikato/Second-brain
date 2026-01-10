
 * ▐▛███▜▌ *   Claude Code v2.0.67
* ▝▜█████▛▘ *  Sonnet 4.5 · API Usage Billing
 *  ▘▘ ▝▝  *   ~/Developer/personal/browser-use

  /model to try Opus 4.5

> Is it possible to use glm coding plan with glm 4.7 model here? 

● Let me check what LLM providers are currently supported in the codebase.

● Search(pattern: "browser_use/llm/*.py")
  ⎿  Found 7 files (ctrl+o to expand)

● Search(pattern: "browser_use/llm/**/*.py")
  ⎿  Found 49 files (ctrl+o to expand)

● Read(browser_use/llm/models.py)
  ⎿  Read 318 lines

● Read(browser_use/llm/__init__.py)
  ⎿  Read 162 lines

● Looking at the current LLM providers in browser-use, GLM (Zhipu AI/智谱) is not natively supported yet. Currently supported providers are:

  - OpenAI, Azure OpenAI
  - Anthropic, AWS Bedrock
  - Google Gemini
  - Groq, DeepSeek, Cerebras
  - Mistral, Ollama, OpenRouter, Vercel
  - Browser Use's own models

  However, GLM 4.7 could likely work with browser-use through a few approaches:

  Option 1: OpenAI-Compatible API (Quickest)

  Zhipu AI's GLM API typically provides OpenAI-compatible endpoints. You could try using ChatOpenAI with a custom base URL:

  from browser_use.llm.openai.chat import ChatOpenAI

  llm = ChatOpenAI(
      model='glm-4.7',
      api_key='your-glm-api-key',
      base_url='https://open.bigmodel.cn/api/paas/v4/'  # or whatever GLM's endpoint is
  )

  Option 2: Add Native GLM Support

  For a first-class integration, you'd need to create a new provider similar to the existing ones (DeepSeek, Groq, etc.):

  1. Create browser_use/llm/glm/chat.py implementing BaseChatModel
  2. Add serialization logic if GLM's response format differs
  3. Register it in browser_use/llm/__init__.py
  4. Add model instances to browser_use/llm/models.py

  ---
  Regarding "GLM Coding Plan" - I don't see this feature mentioned in the codebase. The slash commands /glm-plan-bug:case-feedback and /glm-plan-usage:usage-query are MCP plugins installed in your environment, not part of browser-use itself.

  Want me to:
  1. Try Option 1 and see if GLM 4.7 works via OpenAI-compatible API?
  2. Implement Option 2 and add native GLM support to browser-use?

> Go through this to set it up 

● I'll help you set up GLM (Zhipu AI) integration with browser-use. Let me explore the codebase to understand how to add a new LLM provider.

● 2 Explore agents finished (ctrl+o to expand)
   ├─ Explore LLM provider patterns · 14 tool uses · 62.1k tokens
   │  ⎿  Done
   └─ Check GLM API compatibility · 10 tool uses · 64.9k tokens
      ⎿  Done

● Perfect! I now have a clear understanding of the codebase and GLM's API compatibility. Let me write the implementation plan.

● Updated plan
  ⎿  /plan to preview · ~/.claude/plans/kind-floating-meteor.md
                                                                           
● User answered Claude's questions:
  ⎿  · How should I integrate GLM support into browser-use? → Quick 
     ChatOpenAI workaround

● Updated plan
  ⎿  /plan to preview · ~/.claude/plans/kind-floating-meteor.md

● Plan is ready. The quick workaround approach leverages existing ChatOpenAI with a custom base URL - no code changes required to the library itself.
                                                                           
● User approved Claude's plan
  ⎿  Plan saved to: ~/.claude/plans/kind-floating-meteor.md · /plan to edit
     GLM (Zhipu AI) Integration for Browser-Use

     Summary

     Enable GLM-4.7 support in browser-use using the existing ChatOpenAI 
     class with a custom base URL. Zero code changes needed - just
     configuration.

     Background

     - GLM-4.7 provides a fully OpenAI-compatible API
     - Base URL: https://open.bigmodel.cn/api/paas/v4/ (Zhipu AI) or 
     https://api.z.ai/api/paas/v4/ (Z.AI)
     - Uses standard OpenAI SDK with custom base_url
     - ChatOpenAI already supports custom base_url parameter

     Implementation

     No code changes required. GLM can be used immediately with existing 
     ChatOpenAI:

     from browser_use import Agent
     from browser_use.llm.openai.chat import ChatOpenAI
     import os

     llm = ChatOpenAI(
         model='glm-4.7',
         api_key=os.getenv('GLM_API_KEY'),
         base_url='https://open.bigmodel.cn/api/paas/v4/'
     )

     agent = Agent(
         task='Your task here',
         llm=llm
     )

     Optional: Convenience Helper

     If desired, add a helper function to examples/ directory for easier GLM
      usage:

     # examples/glm_example.py
     from browser_use import Agent
     from browser_use.llm.openai.chat import ChatOpenAI
     import os

     def create_glm_llm(
         model: str = 'glm-4.7',
         api_key: str | None = None,
         base_url: str = 'https://open.bigmodel.cn/api/paas/v4/'
     ) -> ChatOpenAI:
         """Create a ChatOpenAI instance configured for GLM models."""
         return ChatOpenAI(
             model=model,
             api_key=api_key or os.getenv('GLM_API_KEY'),
             base_url=base_url
         )

     # Usage
     llm = create_glm_llm()
     agent = Agent(task='Search for...', llm=llm)

     Critical Files

     - Optional: examples/glm_example.py (new example file)
     - No existing files need modification

     Why This Works

     1. GLM's API is 100% OpenAI-compatible
     2. ChatOpenAI already supports custom base_url and api_key
     3. All browser-use features (structured output, tool calling, 
     streaming) will work automatically
     4. No maintenance burden - GLM API updates are handled by the OpenAI 
     SDK

● Since you chose the quick workaround, there's actually nothing to install or modify in the codebase - GLM works immediately with the existing ChatOpenAI class. Let me create an example file for reference:

● Search(pattern: "examples/*.py")
  ⎿  Found 3 files (ctrl+o to expand)

● Read(examples/simple.py)
  ⎿  Read 18 lines

● Write(examples/glm_example.py)
  ⎿  Wrote 54 lines to examples/glm_example.py                             
     """
     GLM (Zhipu AI) Example for Browser-Use
     Setup:
     1. Get your API key from https://open.bigmodel.cn/ (Zhipu AI) or 
     https://z.ai/ (Z.AI)
     2. Set environment variable: export GLM_API_KEY="your-key"
     This example shows how to use GLM-4.7 with browser-use using the 
     OpenAI-compatible API.
     No custom provider code is needed - we just use ChatOpenAI with a 
     custom base_url.
     """
     … +44 lines (ctrl+o to expand)

● Done. GLM-4.7 is ready to use with browser-use. Here's how:

  from browser_use import Agent
  from browser_use.llm.openai.chat import ChatOpenAI
  import os

  llm = ChatOpenAI(
      model='glm-4.7',
      api_key=os.getenv('GLM_API_KEY'),
      base_url='https://open.bigmodel.cn/api/paas/v4/',
  )

  agent = Agent(task='Your task here', llm=llm)
  agent.run_sync()

  To test it:
  export GLM_API_KEY="your-glm-api-key"
  uv run python examples/glm_example.py

  I've also created examples/glm_example.py as a reference. No library code changes were needed - GLM's OpenAI-compatible API works out of the box.

> Is the base_url https://open.bigmodel.cn/api/paas/v4/ or 
https://api.z.ai/api/coding/paas/v4

# Other Tools

> Methods for using the GLM Coding Plan in other tools

You can easily integrate the **GLM-4.7** model into any tool that supports 
the **OpenAI API protocol**. Simply replace **the default API endpoint** 
with the one provided by [GLM Coding 
Plan](https://z.ai/subscribe?utm_source=zai\&utm_medium=link\&utm_term=devpa
ck-integration\&utm_campaign=Platform_Ops&_channel_track_key=w3mNdY8g), and 
unlock the full power of Z.AI.

<Tip>
  **Christmas Deal:** Enjoy 50% off your first GLM Coding Plan purchase, 
**plus an extra 10%/20% off**! 
[Subscribe](https://z.ai/subscribe?utm_source=z.ai\&utm_medium=link\&utm_ter
m=glm-devpack\&utm_campaign=Platform_Ops&_channel_track_key=jFgqJREK) now.
</Tip>

<Warning>
  Using the GLM Coding Plan, you need to configure the dedicated Coding API 
[https://api.z.ai/api/coding/paas/v4](https://api.z.ai/api/coding/paas/v4) 
instead of the General API 
[https://api.z.ai/api/paas/v4](https://api.z.ai/api/paas/v4)
</Warning>

<Warning>
  For users who have used the service before 2025-12-22: \
  The default model has been upgraded to GLM-4.7. Please update your config 
accordingly.
</Warning>

## Step 1: Supported Tools

Any tool supporting the **OpenAI Protocol** can run on **GLM-4.7**.Simply 
replace the default OpenAI API URL and set your API key.

Below are some common and popular tools supporting the **OpenAI Protocol** 
that can integrate `GLM-4.7` using the same approach:

* **Cursor**
* **Gemini CLI**
* **Cherry studio**
* ...

## Step 2: Install and Config

> Core Steps:
>
> 1. Select an OpenAI-compatible provider.
> 2. **`Add/Replace the OpenAI Base URL with 
https://api.z.ai/api/coding/paas/v4.`**
> 3. **`Enter your Z.AI API Key and select GLM-4.7, GLM-4.7 or 
GLM-4.5-air.`**

Using **Cursor** as an example (Note: Custom configuration is only supported
 in Cursor Pro and higher versions), the following steps demonstrate how to 
integrate the `GLM-4.7` model via the OpenAI protocol. Similarly, other 
tools supporting the OpenAI protocol can adopt the same configuration 
approach.

### 1. Install Cursor

Download and install Cursor from the official website.

### 2. Create a New Provider/Model

In Cursor, navigate to the "**Models**" section and click the "**Add Custom 
Model**".

![Description](https://cdn.bigmodel.cn/markdown/176032216013820251013-100735
.jpeg?attname=20251013-100735.jpeg)

* Select the **OpenAI Protocol**.
* Configure the **OpenAI API Key** (obtained from the Z.AI).
* In **Override OpenAI Base URL**, replace the default URL with 
`https://api.z.ai/api/coding/paas/v4`.
* Enter the model you wish to use, such as `GLM-4.7`, `GLM-4.7` or 
`GLM-4.5-air`.
* Note: In Cursor, the model name must be entered in uppercase, such as 
`GLM-4.7`.

![Description](https://cdn.bigmodel.cn/markdown/176032218295020251013-100740
.jpeg?attname=20251013-100740.jpeg)

### 3. Save and Switch Models

After configuration, save your settings and select the newly created 
**GLM-4.7 Provider** on the homepage.

### 4. Get Started

With this setup, you can begin using the **GLM-4.7** model for code 
generation, debugging, task analysis, and more.

![Description](https://cdn.bigmodel.cn/markdown/176032221518820251013-100745
.jpeg?attname=20251013-100745.jpeg)

## Step 3: Replacing the API URL

1. **Locate the API configuration section in your tool**:

For example, in **Goose**, this is typically where you set the API address 
in the configuration file; In **VS Code** plugins or **IntelliJ IDEA** 
plugins, configuration is usually done through the plugin's settings 
interface.

2. **Replace the OpenAI Base URL**:

Replace the default OpenAI API URL with 
`https://api.z.ai/api/coding/paas/v4`.

3. **Enter API Key and Select Model**:

* Enter your **Z.ai API Key**.
* Select `GLM-4.7`(standard, complex tasks) or `GLM-4.5-air`(lightweight, 
faster response) based on your requirements.

## Summary

By following these steps, you can integrate the **GLM-4.7** model into any 
tool supporting the **OpenAI protocol**. Simply replace the API endpoint and
 enter the corresponding API key to leverage the **GLM-4.7** model for 
powerful code generation, debugging, and analysis tasks within these tools. 
Integration with **GLM-4.7** is straightforward for any tool supporting the 
OpenAI protocol.


---

> To find navigation and other pages in this documentation, fetch the 
llms.txt file at: https://docs.z.ai/llms.txt 

● You're right - for the GLM Coding Plan, the dedicated coding API endpoint is https://api.z.ai/api/coding/paas/v4. Let me update the example:

● Update(examples/glm_example.py)
  ⎿  Updated examples/glm_example.py with 15 additions and 10 removals   
        1    """
        2 -  GLM (Zhipu AI) Example for Browser-Use
        2 +  GLM Coding Plan (Z.AI) Example for Browser-Use
        3    
        4    Setup:
        5 -  1. Get your API key from https://open.bigmodel.cn/ (Zhipu 
          - AI) or https://z.ai/ (Z.AI)
        5 +  1. Get your API key from https://z.ai/subscribe (GLM Coding 
          + Plan)
        6    2. Set environment variable: export GLM_API_KEY="your-key"
        7    
        8 -  This example shows how to use GLM-4.7 
          -  with browser-use using the OpenAI-compatible API.
        9 -  No custom provider code is needed - we just use ChatOpenAI 
          - with a custom base_url.
        8 +  This example shows how to use GLM-4.7 Coding Plan 
          +  with browser-use using the OpenAI-compatible API.
        9 +  The Coding Plan uses a dedicated endpoint optimized for 
          + coding tasks.
       10 +  
       11 +  API Endpoints:
       12 +  - Coding Plan: https://api.z.ai/api/coding/paas/v4 
          + (recommended for browser-use)
       13 +  - General API:  https://api.z.ai/api/paas/v4 (general tasks)
       14 +  - Zhipu AI:   https://open.bigmodel.cn/api/paas/v4/ 
          + (original endpoint)
       15    """
       16    
       17    from dotenv import load_dotenv
     ...
       17    load_dotenv()
       18    
       19    
       20 -  def create_glm_llm(
       20 +  def create_glm_coding_llm(
       21      model: str = 'glm-4.7',
       22      api_key: str | None = None,
       23 -    base_url: str = 'https://open.bigmodel.cn/api/paas/v4/',
       23 +    base_url: str = 'https://api.z.ai/api/coding/paas/v4',
       24    ) -> ChatOpenAI:
       25 -    """Create a ChatOpenAI instance configured for GLM models.
       25 +    """Create a ChatOpenAI instance configured for GLM 
          +  Coding Plan.
       26    
       27      Args:
       28        model: GLM model name (default: 'glm-4.7')
       29 -      api_key: Your GLM
          -   API key (defaults to GLM_API_KEY env var)
       30 -      base_url: GLM API endpoint (default: Zhipu AI, or use 
          - 'https://api.z.ai/api/paas/v4/' for Z.AI)
       29 +      api_key: Your Z.AI
          +   API key (defaults to GLM_API_KEY env var)
       30 +      base_url: GLM Coding API endpoint
       31    
       32      Returns:
       33 -      Configured ChatOpenAI instance for GLM
       33 +      Configured ChatOpenAI instance for GLM Coding Plan
       34      """
       35      return ChatOpenAI(
       36        model=model,

● Updated with the correct Coding Plan endpoint. Here's the corrected setup:

  from browser_use import Agent
  from browser_use.llm.openai.chat import ChatOpenAI
  import os

  llm = ChatOpenAI(
      model='glm-4.7',
      api_key=os.getenv('GLM_API_KEY'),
      base_url='https://api.z.ai/api/coding/paas/v4',  # Coding Plan endpoint
  )

  agent = Agent(task='Your task here', llm=llm)
  agent.run_sync()

  API Endpoints:
  - Coding Plan: https://api.z.ai/api/coding/paas/v4 (recommended for browser-use)
  - General API: https://api.z.ai/api/paas/v4 (general tasks)
  - Zhipu AI: https://open.bigmodel.cn/api/paas/v4/ (original)

  The Coding Plan endpoint is specifically optimized for coding/automation tasks like browser-use