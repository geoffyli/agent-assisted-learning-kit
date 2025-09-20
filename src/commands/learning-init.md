# Learning Session Initialization Command

## Purpose
Initialize a new learning session through interactive specification gathering, creating complete learning plans.

## Command Description
This command creates a comprehensive learning session in the `learn/` directory through guided interaction. Instead of empty templates, it builds a complete specification by asking targeted questions and generating detailed learning plans based on user responses.

## Agent Instructions

You are helping the user create a structured learning session. Follow these phases exactly:

---

## PHASE 0: PRE-VALIDATION

**0.1. Run Prerequisites Validation**
- Execute: `.agent/scripts/validate-learning-prerequisites.sh --json "$TOPIC_NAME"`
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
  * "What specific skills do you want to gain from learning {TOPIC}? A) Practical implementation ability, B) Theoretical understanding, C) Both theory and practice, D) Other (please specify)"
  * "After completing this learning session, what should you be able to do, build, or explain?"
  * "What's your primary motivation for learning this? A) Work/career needs, B) Personal project, C) Academic requirement, D) General interest"

**1.2. Scope Definition**
- STOP and ASK USER about boundaries and focus:
  * "What specific aspects of {TOPIC} should be included? (List the key areas you want to cover)"
  * "What aspects should be excluded to keep the scope manageable?"
  * "How deep should we go? A) Basic/introductory level, B) Intermediate practical level, C) Advanced/expert level"

**1.3. Background Assessment**
- STOP and ASK USER about their current knowledge:
  * "What do you already know about {TOPIC} or related concepts?"
  * "Have you tried learning this before? If so, what worked/didn't work?"
  * "What related technologies or concepts are you familiar with?"

**1.4. Resources & Environment**
- STOP and ASK USER about available materials:
  * "Do you have specific learning materials in mind? Please list any documentation, courses, books, or tutorials you want to use"
  * "Do you have access to practice environments or tools needed for hands-on work?"

- **Resource Research & Recommendation**:
  * If user provides no materials OR user provides some materials but wants more recommendations:
    - Research high-quality learning resources for {TOPIC} (official docs, recommended courses, books, tutorials)
    - STOP and present organized list of recommended resources with brief descriptions
    - Ask user: "I've found these recommended learning resources. Please review and let me know: A) Use these recommendations, B) Add specific ones to your list, C) You'll add resources manually later"
  * WAIT for user confirmation before proceeding
  * Include both user-provided AND approved recommended resources in final specification

- **Manual Resource Addition**:
  * Inform user: "You can manually add more resources to the resources.md file after session creation if you discover additional materials during learning"

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
- **Script Purpose**: Creates session directory in `learn/` with proper naming (YYYY-MM-DD Topic Name)
- Parse JSON output for: `SESSION_PATH`, `SESSION_NAME`, `FILES_CREATED`

**2.2. Create Complete Specification Files**
- Use gathered information to populate template placeholders
- Generate comprehensive, actionable content (not empty templates)
- Create files with real content based on user responses:
  * `learning-spec.md` - Complete specification with all gathered details (goals, scope, criteria)
  * `resources.md` - Organized list of specific resources user mentioned
  * `learning-plan.md` - Basic structure ready for STRUCTURE phase with integrated progress tracking

**Template Processing Instructions for SCOPE Phase:**
- Load `src/templates/learning-spec-template.md` and `src/templates/resources-template.md`
- Load `src/templates/learning-plan-template.md` for basic initialization only
- **Do NOT populate** learning-plan template beyond basic initialization
- Generate 3 complete files with no remaining placeholders

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
- Plus all resources placeholders: `{OFFICIAL_DOCUMENTATION}`, `{BOOKS_MATERIALS}`, `{STRUCTURED_COURSES}`, etc.

**Content Processing Guidelines:**
- Convert user responses into structured, actionable content
- Format lists as markdown bulleted lists
- Ensure all content is specific and actionable
- Avoid generic or vague statements
- Include concrete examples when possible
- Ensure content aligns with user's stated goals and preferences

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
- **DO NOT** proceed to planning, structure creation, or any other phases
- **DO NOT** automatically run next learning commands
- Wait for explicit user instruction to proceed to structure phase

**3.2. Next Steps Guidance**
- Explain that the specification phase is complete
- Tell user they can now proceed to the structure phase when ready
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
- Ready for next phase (structure) when user chooses to proceed