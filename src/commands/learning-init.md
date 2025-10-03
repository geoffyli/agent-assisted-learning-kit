# Learning Session Initialization Command

## Purpose
Initialize a new learning session through interactive specification gathering, creating complete learning plans.

## Command Description
This command creates a comprehensive learning session in the `learn/` directory through guided interaction. It will instruct agent to interact with user, asking targeted questions, and generate detailed learning specification based on user responses.

## Command Usage
```
learning-init [TOPIC_NAME]
```

**TOPIC_NAME** should be:
- A descriptive topic name for your learning session
- Will be used to create session directory and identify the learning topic
- Examples: `"React Development"`, `"Python Machine Learning"`, `"Docker Containerization"`

**Examples:**
```
learning-init "React Development"
learning-init "Python Machine Learning" 
learning-init "Advanced JavaScript"
```

## Agent Instructions

You are helping the user create a structured learning session. Follow these phases exactly:

---

## INPUT PARAMETER PROCESSING

**Parameter Handling:**
- Accept TOPIC_NAME as command parameter
- TOPIC_NAME should be a descriptive learning topic name
- If no parameter provided, ask user to provide the topic name

**Topic Name Validation:**
- If TOPIC_NAME provided:
  - Set TOPIC_NAME variable for use throughout command
  - Proceed to Phase 0
- If no TOPIC_NAME provided:
  - STOP and ask user for topic name:
    
    ```
    No learning topic specified. 
    
    What topic would you like to learn?
    Please provide a descriptive topic name (e.g., "React Development", "Python Machine Learning"):
    ```
    
  - WAIT for user input
  - Set TOPIC_NAME to user's response
  - Proceed to Phase 0

**Topic Name Processing:**
- Use TOPIC_NAME throughout the command for personalization
- TOPIC_NAME will be used in:
  - Script validation calls
  - Session directory creation  
  - Template placeholder replacement
  - User interaction messaging

---

## PHASE 0: PRE-VALIDATION

**0.1. Run Prerequisites Validation**
- Execute: `.agent/scripts/validate-init-prerequisites.sh --json "$TOPIC_NAME"`
- **Script Purpose**: Validates vault structure, checks for existing sessions, verifies topic name validity
- Parse JSON output for: `success`, `errors`, `warnings`, `current_path`

**FAILURE ACTIONS** (if success = false):
- For each error in the errors array, STOP execution and respond with the exact error message
- Do NOT proceed to Phase 1 under any circumstances
- Provide specific remediation steps from the error messages

**WARNING ACTIONS** (if warnings exist but success = true):
- Display each warning message to the user
- Ask for confirmation: "Warnings detected above. Type 'continue' to proceed or provide more specific description."
- Only proceed to Phase 1 if user confirms with 'continue'

---

## PHASE 1: INTERACTIVE LEARNING SPECIFICATION

**1.1. Learning Goal Clarification**
- STOP and ASK USER specific questions about their learning objectives:
  * "What specific skills do you want to gain from learning [TOPIC_NAME]? A) Practical implementation ability, B) Theoretical understanding, C) Both theory and practice, D) Other (please specify)"
  * "After completing this learning session, what should you be able to do, build, or explain?"
  * "What's your primary motivation for learning this? A) Work/career needs, B) Personal project, C) Academic requirement, D) General interest"

**1.2. Scope Definition**
- STOP and ASK USER about boundaries and focus:
  * "What specific aspects of [TOPIC_NAME] should be included? (List the key areas you want to cover)"
  * "What aspects should be excluded to keep the scope manageable?"
  * "How deep should we go? A) Basic/introductory level, B) Intermediate practical level, C) Advanced/expert level"

**1.3. Background Assessment**
- STOP and ASK USER about their current knowledge:
  * "What do you already know about [TOPIC_NAME] or related concepts?"
  * "Have you tried learning this before? If so, what worked/didn't work?"
  * "What related technologies or concepts are you familiar with?"

**1.4. Practice Environment**
- STOP and ASK USER about available tools and setup:
  * "Do you have access to practice environments or tools needed for hands-on work with [TOPIC_NAME]?"
  * "What development environment or tools do you plan to use for practicing?"

**1.5. Success Criteria Definition**
- STOP and ASK USER how they'll measure success:
  * "How will you know you've successfully learned this? What should you be able to demonstrate?"
  * "What practical project or outcome would prove your mastery?"
  * "Are there specific milestones or checkpoints you want to set?"

**WAIT FOR USER RESPONSES** to each section before proceeding. Do not guess or make assumptions.

---

## PHASE 2: SPECIFICATION GENERATION

**2.1. Generate Learning Session Structure**
- Run: `.agent/scripts/create-learning-session.sh --json "$TOPIC_NAME"`
- **Script Purpose**: Creates session directory and template files in `learn/` with proper naming (YYYY-MM-DD Topic Name)
- Parse JSON output for: `SESSION_PATH`, `SESSION_NAME`, `FILES_CREATED`

**2.2. Create Complete Specification File**
- Use gathered information to populate template placeholders
- Update `learning-spec.md` with real content based on user responses: Complete specification with all gathered details (goals, scope, criteria)

**Template Processing Instructions for SCOPE Phase:**
- Templates are automatically copied to session directory by `create-learning-session.sh` script with frontmatter removed and renamed to final names: `learning-spec.md`, `resources.md`, and `learning-plan.md`
- **Do NOT populate** learning-plan.md beyond basic initialization

**Key Template Placeholders to Replace:**
- `{TOPIC_NAME}` - The learning topic name provided by user
- `{CREATION_DATE}` - Current date in YYYY-MM-DD format
- `{LEARNING_DEPTH}` - Level: Basic/Intermediate/Advanced
- `{LEARNING_GOAL_DESCRIPTION}` - Detailed learning objectives from user responses
- `{SKILL_TYPE_FOCUS}` - Practical/Theoretical/Both based on user preference
- `{TOPICS_TO_INCLUDE}` - Bulleted list of specific areas to cover
- `{TOPICS_TO_EXCLUDE}` - Bulleted list of areas to avoid/defer
- `{BACKGROUND_KNOWLEDGE}` - User's existing knowledge and experience
- `{PREVIOUS_ATTEMPTS}` - Any prior learning attempts and outcomes
- `{RELATED_EXPERIENCE}` - Adjacent skills or concepts user knows
- `{PRACTICE_ENVIRONMENT}` - Tools/setup user has access to
- `{COMPLETION_INDICATORS}` - How user will know they've succeeded
- `{PRACTICAL_DEMONSTRATION}` - Project/outcome to prove mastery
- `{MILESTONES_CHECKPOINTS}` - Specific progress markers user wants

**Content Processing Guidelines:**

**Language Transformation Rules:**
- **Convert first person to specification language**: Transform "I want to learn..." → "Develop knowledge of..."
- **Use professional documentation tone**: Avoid conversational language, use formal specification style
- **Remove personal pronouns**: Replace "I am familiar with..." → "Background includes experience with..."
- **Make content objective**: Transform "I think..." → "Focus areas include..." or "Approach emphasizes..."

**Content Restructuring Standards:**
- **Learning Goals**: Transform user desires into clear, measurable learning objectives
- **Background Knowledge**: Reformat experience descriptions into structured skill inventory
- **Success Criteria**: Convert user hopes into specific, actionable completion indicators
- **Practice Environment**: Transform availability statements into capability descriptions

**Format Requirements:**
- Use bullet points for lists and structured information
- Write in third person or neutral specification language
- Ensure all content is specific, actionable, and professional
- Eliminate conversational fillers ("well", "I think", "maybe")
- Structure content logically within each section

**2.3. Quality Assurance**
- Verify all mandatory information is included
- Check that specifications are actionable and specific
- Ensure no placeholder text remains

---

## PHASE 3: COMPLETION AND HANDOFF

**3.1. STOP and Report Completion**
- **IMMEDIATELY STOP** all execution after completing the specification
- Report completion with:
  * Session name and location in `learn/` directory
  * Confirmation that specification is complete and ready
  * Brief summary of learning goals and scope
  * **Important**: Remind user to add learning materials to `Resources/` folder and update `resources.md` index before proceeding to PLAN phase
- **DO NOT** proceed to planning, plan creation, or any other phases
- **DO NOT** automatically run next learning commands
- Wait for explicit user instruction to proceed to plan phase

**3.2. Next Steps Guidance**
- Explain that the specification phase is complete
- Tell user they can now proceed to the plan phase when ready
- Mention they can review and modify the generated specifications if needed

---

## Error Handling
- If prerequisites fail, provide specific remediation steps
- If user responses are unclear, ask follow-up questions
- If script execution fails, report exact error and suggest solutions
- Never proceed with incomplete information

## CONTINUOUS VALIDATION PRINCIPLES
*Apply throughout all phases*

- **Never Assume**: If ANY aspect becomes unclear during execution, **IMMEDIATELY STOP and ASK USER** for clarification
- **Handle Ambiguity Constructively**: When users respond with "I don't know", provide informed recommendations with clear rationale and ask for confirmation
- **Material-First Research**: When uncertain about technological topics, request user materials rather than relying on potentially outdated knowledge
- **Knowledge Transparency**: Explicitly declare confidence levels - "I'm not familiar with X" rather than guessing
- **User-Aligned Decisions**: All choices must align with user-stated preferences and constraints
- **Progressive Disclosure**: Ask questions in logical order - don't overwhelm with all decisions at once
- **Validate Alignment**: Before generating each major artifact, confirm the approach matches user expectations and provided materials
- **Escalation Strategy**: If uncertainty persists after recommendations, gather more context about constraints and preferences

---

## Success Criteria
- Prerequisites validation passes
- Complete specification generated from user interaction
- All files contain real content (no empty templates)
- User has clear understanding of what was created
- Ready for next phase (plan) when user chooses to proceed