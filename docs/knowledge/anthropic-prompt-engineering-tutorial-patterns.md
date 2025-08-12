# Anthropic Prompt Engineering Tutorial - Complete Pattern Library

## Overview

This document captures the complete structure, techniques, and patterns from Anthropic's official prompt engineering interactive tutorial. The tutorial consists of 13 notebooks covering fundamental to advanced prompt engineering techniques with practical examples and exercises.

## Tutorial Structure

### Core Chapters (9 Main Topics)
1. **Basic Prompt Structure** - Foundation concepts and prompt anatomy
2. **Being Clear and Direct** - Precision in communication and instruction clarity
3. **Assigning Roles (Role Prompting)** - Role-based prompting for specialized tasks
4. **Separating Data and Instructions** - Structural organization using XML tags
5. **Formatting Output and Speaking for Claude** - Output control and prefill techniques
6. **Precognition (Thinking Step by Step)** - Chain-of-thought reasoning patterns
7. **Using Examples (Few-Shot Prompting)** - Example-based learning techniques
8. **Avoiding Hallucinations** - Evidence-based response generation
9. **Complex Prompts from Scratch** - Advanced prompt construction

### Appendix (Advanced Topics)
- **10.1 Chaining Prompts** - Multi-step prompt workflows
- **10.2 Tool Use** - Integration with external tools and APIs
- **10.3 Search & Retrieval** - Information retrieval and processing

## XML Tag Patterns Library

### Core Structural Tags

#### Data Organization
```xml
<instructions>
Your task is to analyze the given data and provide insights.
</instructions>

<data>
[Input data goes here]
</data>

<context>
Additional background information relevant to the task.
</context>
```

#### Response Structure
```xml
<thinking>
Let me work through this step by step:
1. First, I need to understand...
2. Then I should consider...
3. Finally, I can conclude...
</thinking>

<answer>
Based on my analysis, the result is...
</answer>
```

#### Evidence-Based Responses
```xml
<evidence>
"Direct quote from source material that supports the conclusion"
</evidence>

<conclusion>
Based on the evidence above, I can conclude that...
</conclusion>
```

### Advanced Reasoning Tags

#### Balanced Analysis
```xml
<positive-argument>
Arguments in favor of this position:
- Point 1 with supporting evidence
- Point 2 with rationale
</positive-argument>

<negative-argument>
Arguments against this position:
- Counterpoint 1 with evidence
- Counterpoint 2 with analysis
</negative-argument>
```

#### Working Memory
```xml
<scratchpad>
Working through the problem:
- Given information: X, Y, Z
- Relationships: A affects B
- Calculations: 2 + 3 = 5
</scratchpad>
```

#### Output Formatting
```xml
<formatting>
Please structure your response as:
1. Summary (2-3 sentences)
2. Key findings (bullet points)
3. Recommendations (numbered list)
</formatting>
```

## Chapter-Specific Techniques

### Chapter 1: Basic Prompt Structure

**Core Principles:**
- **Prompt Anatomy**: Task description + context + specific instructions + examples
- **Processing Order**: Claude reads sequentially, recent information has more weight
- **Clarity Imperative**: Be explicit about what you want

**Pattern Example:**
```
Task: [What you want Claude to do]
Context: [Background information]
Instructions: [Specific steps or requirements]
Format: [How you want the output structured]
```

### Chapter 2: Being Clear and Direct

**Key Techniques:**
- **Precision Over Politeness**: Direct instructions work better than polite requests
- **Detail Specification**: Include specifics about length, format, tone, audience
- **Typo Impact**: Small errors can significantly affect output quality

**Effective Pattern:**
```
Write a technical summary of [topic] that:
- Is exactly 200 words
- Uses technical language appropriate for engineers
- Includes 3 specific examples
- Avoids marketing language
```

### Chapter 3: Assigning Roles (Role Prompting)

**Role Assignment Patterns:**
```xml
<role>
You are an expert data scientist with 10 years of experience in machine learning.
Your expertise includes statistical analysis, model validation, and business intelligence.
</role>

<task>
Analyze the following dataset and provide insights...
</task>
```

**System Message Integration:**
- Use system messages for persistent roles
- Combine with user messages for specific tasks
- Maintain role consistency throughout conversation

### Chapter 4: Separating Data and Instructions

**XML Organization Benefits:**
- Clear separation prevents instruction/data confusion
- Enables complex data processing
- Improves reliability with large inputs

**Standard Structure:**
```xml
<instructions>
Analyze the customer feedback data and identify:
1. Most common complaints
2. Sentiment trends
3. Actionable recommendations
</instructions>

<data>
[Large dataset or multiple data sources]
</data>

<format>
Provide results in JSON format with keys: complaints, sentiment, recommendations
</format>
```

### Chapter 5: Formatting Output and Speaking for Claude

**Prefill Technique:**
```
Human: Analyze this code for bugs:
[code here]

Assistant: Looking at this code, I can identify the following issues:

1. **[Bug type 1]**: [description]
2. **[Bug type 2]**: [description]
3. **[Bug type 3]**: [description]
```

**Output Control Patterns:**
- **Prefill starts the response** - Forces Claude to begin with specific format
- **JSON structure forcing** - Use prefill like `Assistant: {` to ensure JSON output
- **Tone/style control** - Start response with desired tone

**Advanced Prefill Examples:**
```
Human: Summarize this report:
[report content]

Assistant: **Executive Summary**

The key findings from this report are:
```

### Chapter 6: Precognition (Thinking Step by Step)

**Chain-of-Thought Reasoning:**
- **Structured thinking** - Break complex problems into steps
- **Explicit reasoning** - Show work before conclusions
- **Self-correction** - Allow Claude to catch and fix errors

**Step-by-Step Pattern:**
```xml
<thinking>
1. Understanding the problem:
   - What is being asked?
   - What information do I have?
   - What am I missing?

2. Planning the approach:
   - Break into sub-problems
   - Identify required steps
   - Consider edge cases

3. Executing the solution:
   - Step 1: [action and result]
   - Step 2: [action and result]
   - Step 3: [action and result]

4. Verification:
   - Does this answer make sense?
   - Have I addressed all parts?
   - Are there any errors?
</thinking>

<answer>
Based on my step-by-step analysis above...
</answer>
```

### Chapter 7: Using Examples (Few-Shot Prompting)

**Few-Shot Learning Patterns:**
- **Pattern recognition** - Show Claude the desired input/output pattern
- **Format consistency** - Examples teach structure and style
- **Edge case handling** - Include examples of difficult cases

**Effective Few-Shot Structure:**
```xml
<examples>
<example>
Input: "The weather is nice today"
Output: Positive sentiment (confidence: 0.8)
Reasoning: Direct positive expression about weather
</example>

<example>
Input: "I guess it's not terrible outside"
Output: Neutral sentiment (confidence: 0.6)
Reasoning: Lukewarm expression with double negative
</example>

<example>
Input: "This rain is ruining everything"
Output: Negative sentiment (confidence: 0.9)
Reasoning: Strong negative emotion and attribution
</example>
</examples>

<task>
Analyze the sentiment of: "It might be sunny later"
</task>
```

**Multishot Prompting Benefits:**
- **Consistency** - Multiple examples reduce variability
- **Complexity handling** - Show how to handle nuanced cases
- **Quality improvement** - More examples = better performance

### Chapter 8: Avoiding Hallucinations

**Evidence-First Methodology:**
1. **Extract evidence** before making claims
2. **Quote directly** from source material
3. **Separate facts from analysis**
4. **Acknowledge limitations**

**Anti-Hallucination Pattern:**
```xml
<instructions>
First, extract all relevant quotes from the document that relate to the question.
Then, based only on those quotes, provide your analysis.
If the document doesn't contain enough information, say so explicitly.
</instructions>

<document>
[Source material here]
</document>

<question>
What are the main conclusions about climate change?
</question>

<response_format>
<evidence>
- Quote 1: "[exact text from document]"
- Quote 2: "[exact text from document]"
- Quote 3: "[exact text from document]"
</evidence>

<analysis>
Based on the evidence above, the main conclusions are:
1. [conclusion based on quote 1]
2. [conclusion based on quote 2]
3. [conclusion based on quote 3]
</analysis>

<limitations>
The document does not provide information about: [list gaps]
</limitations>
</response_format>
```

### Chapter 9: Complex Prompts from Scratch

**Advanced Prompt Architecture:**
- **Layered instructions** - General → Specific → Format
- **Multiple techniques** - Combine role-playing, examples, reasoning
- **Error prevention** - Build in safeguards and validations

**Complex Prompt Template:**
```xml
<system_context>
You are a [role] with expertise in [domain].
Your task is to [high-level objective].
</system_context>

<instructions>
1. [Primary instruction]
2. [Secondary instruction]
3. [Tertiary instruction]

Constraints:
- [Constraint 1]
- [Constraint 2]
- [Constraint 3]
</instructions>

<examples>
[2-3 high-quality examples showing desired pattern]
</examples>

<data>
[Input data or context]
</data>

<thinking_process>
Before responding, work through:
1. Understanding: What exactly is being asked?
2. Analysis: What patterns do I see in the data?
3. Reasoning: How do I apply the instructions?
4. Validation: Does my response meet all requirements?
</thinking_process>

<output_format>
[Specific format requirements]
</output_format>
```

## Advanced Integration Patterns

### Combining Multiple Techniques

**Example: Research Analysis with Multiple Methods**
```xml
<role>
You are a senior research analyst with expertise in market trends and data interpretation.
</role>

<task>
Analyze the provided market data and create a comprehensive report.
</task>

<instructions>
1. Extract key data points and quotes (anti-hallucination)
2. Analyze trends step-by-step (chain-of-thought)
3. Consider both positive and negative implications (balanced analysis)
4. Provide actionable recommendations
</instructions>

<examples>
[Previous analysis examples showing the desired format and depth]
</examples>

<data>
[Market data, reports, statistics]
</data>

<thinking>
[Step-by-step analysis process]
</thinking>

<evidence>
[Key quotes and data points extracted]
</evidence>

<positive_argument>
[Optimistic interpretation with supporting evidence]
</positive_argument>

<negative_argument>
[Cautionary interpretation with supporting evidence]
</negative_argument>

<recommendations>
[Actionable next steps based on balanced analysis]
</recommendations>
```

### Hierarchical Prompt Structure

**For Complex Multi-Step Tasks:**
```xml
<meta_instructions>
This is a complex task requiring multiple analysis phases.
Complete each phase fully before moving to the next.
</meta_instructions>

<phase_1>
<goal>Data extraction and validation</goal>
<instructions>Extract and verify all relevant data points</instructions>
<output_format>Structured data summary with confidence levels</output_format>
</phase_1>

<phase_2>
<goal>Pattern analysis</goal>
<instructions>Identify trends, correlations, and anomalies</instructions>
<required_input>Results from Phase 1</required_input>
<output_format>Analytical findings with supporting evidence</output_format>
</phase_2>

<phase_3>
<goal>Strategic recommendations</goal>
<instructions>Develop actionable recommendations based on analysis</instructions>
<required_input>Results from Phase 1 and 2</required_input>
<output_format>Prioritized recommendation list with rationale</output_format>
</phase_3>
```

## Appendix Techniques

### 10.1 Chaining Prompts

**Sequential Processing Pattern:**
- **Output becomes input** - Each prompt builds on previous results
- **State management** - Maintain context across prompt chain
- **Error handling** - Build validation into each step

**Chain Example:**
```
Prompt 1: Extract key concepts from document
Prompt 2: Categorize concepts using output from Prompt 1
Prompt 3: Generate summary using categorized concepts from Prompt 2
```

### 10.2 Tool Use Integration

**Tool-Augmented Prompting:**
```xml
<instructions>
Use the available tools to gather information before providing analysis.
Order of operations:
1. Search for recent data using web_search
2. Calculate any necessary metrics using calculator
3. Generate visualizations if helpful using chart_tool
4. Provide comprehensive analysis based on gathered information
</instructions>

<available_tools>
- web_search: Search for current information
- calculator: Perform mathematical calculations
- chart_tool: Create data visualizations
</available_tools>
```

### 10.3 Search & Retrieval Optimization

**Information Retrieval Pattern:**
```xml
<search_strategy>
1. Query formulation: Break question into searchable components
2. Source evaluation: Assess reliability and relevance
3. Information synthesis: Combine multiple sources coherently
4. Gap identification: Note what information is missing
</search_strategy>

<retrieval_instructions>
For each search result:
1. Extract key facts and quotes
2. Note the source and date
3. Assess credibility
4. Identify relationships to other sources
</retrieval_instructions>
```

## Best Practices Summary

### High-Impact Techniques
1. **XML structure** for complex prompts
2. **Chain-of-thought** for reasoning tasks
3. **Few-shot examples** for consistent formatting
4. **Evidence extraction** to prevent hallucinations
5. **Role assignment** for specialized expertise
6. **Prefill technique** for output control

### Common Pitfalls to Avoid
- **Ambiguous instructions** - Be specific about requirements
- **Missing examples** - Show don't just tell
- **Overcomplex prompts** - Start simple, add complexity gradually
- **Inconsistent formatting** - Maintain structure throughout
- **Ignoring context limits** - Consider token constraints

### Prompt Engineering Workflow
1. **Define objective** clearly
2. **Choose techniques** based on task type
3. **Structure prompt** with appropriate tags
4. **Test and iterate** with real examples
5. **Optimize performance** through refinement

## Tags Reference

**Essential Tags:**
- `<instructions>` - Task definition
- `<data>` - Input information
- `<thinking>` - Reasoning process
- `<answer>` - Final response
- `<examples>` - Pattern demonstration
- `<format>` - Output structure

**Specialized Tags:**
- `<evidence>` - Supporting quotes
- `<scratchpad>` - Working memory
- `<positive_argument>` / `<negative_argument>` - Balanced analysis
- `<role>` - Expertise assignment
- `<context>` - Background information
- `<limitations>` - Boundary acknowledgment

This pattern library provides a comprehensive foundation for effective prompt engineering across all complexity levels, from basic single-turn interactions to sophisticated multi-step reasoning workflows.