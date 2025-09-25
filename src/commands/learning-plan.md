# Learning Session Plan Command

## Purpose
Transform completed learning specification into detailed, executable learning plan with full MOC integration and note organization planning.

## Command Description
This command takes a completed SCOPE phase session and creates comprehensive structural planning through interactive design. It bridges the gap between "what to learn" and "exactly how to execute the learning" with full vault integration.

## Command Usage
```
learning-plan [SESSION_IDENTIFIER]
```

**SESSION_IDENTIFIER** can be:
- Full session path: `/vault/learn/2024-09-21 React Development`
- Session name: `"2024-09-21 React Development"`
- Topic name: `"React Development"` (finds session by topic)
- Partial match: `"React"` (with disambiguation if multiple matches)

**Examples:**
```
learning-plan "React Development"
learning-plan "2024-09-21 React Development"
learning-plan "Python"
```

## Agent Instructions

You are helping the user create a structured learning plan from their completed specification. Follow these phases exactly:

- When filling the `learning-plan-template.md`, make sure to remove the instructional comments (i.e., the text within `<!-- -->`) from the template.


---

## INPUT PARAMETER PROCESSING

**Parameter Handling:**
- Accept SESSION_IDENTIFIER as command parameter
- SESSION_IDENTIFIER can be: full path, session name, topic name, or partial match
- If no parameter provided, list available learning sessions and ask user to select
- Handle disambiguation when multiple sessions match the identifier

**Session Discovery Process:**
1. Execute: `.agent/scripts/find-learning-session.sh --json "$SESSION_IDENTIFIER"`
2. Parse JSON output for: `success`, `session_path`, `session_name`, `status`, `matches`, `available_sessions`, `error`
3. Filter for sessions that have completed SCOPE phase (have learning-spec.md and resources.md)

**Session Discovery Results:**

**SUCCESS (success = true):**
- Set SESSION_PATH to the returned session_path
- Set SESSION_NAME to the returned session_name  
- Verify session is ready for PLAN phase (has learning-spec.md and resources.md)
- Log: "Found learning session: [SESSION_NAME]"
- Proceed to Phase 0

**DISAMBIGUATION NEEDED (disambiguation_needed = true):**
- STOP and present disambiguation menu to user:
  
  ```
  Multiple learning sessions match '[SESSION_IDENTIFIER]':
  
  [For each match in matches object that has completed SCOPE]
  [N]) [Session Name] - Status: [Status]
  
  Which session would you like to plan? (Enter number)
  ```
  
- WAIT for user selection
- Re-run session discovery with the selected session name
- Proceed to Phase 0 with confirmed session

**NO SESSIONS FOUND (success = false, no disambiguation_needed):**
- STOP execution and inform user of the error
- Present available sessions that have completed SCOPE phase:
  
  ```
  [Error message from script]
  
  Available learning sessions ready for planning:
  [For each session with SCOPE complete]
  - [Session Name] - Status: [Status]
  
  Please specify a valid session identifier.
  ```
  
- Do NOT proceed to Phase 0

**NO IDENTIFIER PROVIDED:**
- STOP and present all available sessions ready for planning:
  
  ```
  Available learning sessions ready for planning:
  [For each session with SCOPE complete]
  [N]) [Session Name] - Status: [Status]
  
  Which session would you like to plan? (Enter number or session name)
  ```
  
- WAIT for user selection
- Re-run session discovery with the selected identifier
- Proceed to Phase 0 with confirmed session

---

## PHASE 0: PRE-VALIDATION

**0.1. Read Vault Guidelines**
- Read the `AGENTS.md` file at vault root to understand vault organization, standards, and agent behavior requirements
- **Key areas to understand**: MOC patterns, wikilink standards, folder organization rules, frontmatter requirements, and content structure guidelines
- Ensure all subsequent actions follow the vault's established patterns and conventions

**0.2. Run Prerequisites Validation**
- Execute: `.agent/scripts/validate-plan-prerequisites.sh --json "$SESSION_PATH"`
- **Script Purpose**: Validates SCOPE phase completion, checks all files exist and are populated, verifies no template placeholders remain
- Parse JSON output for: `success`, `errors`, `warnings`, `session_status`

**SCRIPT EXECUTION FAILURE ACTIONS** (if script fails to run):
- If script cannot be executed (permissions, not found, execution error):
  - **IMMEDIATELY STOP** and inform user of the specific execution error
  - Ask user: "The validation script failed to execute due to [specific error]. Would you like to proceed with manual confirmation of the prerequisites instead?"
  - If user chooses manual confirmation, verify:
    - `learning-spec.md` exists and contains completed specification content
    - `resources.md` exists and contains resource information
    - No obvious template placeholders remain (e.g., {TOPIC_NAME}, {PLACEHOLDER})
    - Session directory structure is intact
  - If manual verification passes, proceed to Phase 1
  - If manual verification fails, provide specific remediation steps

**VALIDATION FAILURE ACTIONS** (if script runs but success = false):
- For each error in the errors array, STOP execution and respond with the exact error message
- Do NOT proceed to Phase 1 under any circumstances
- Provide specific remediation steps: guide user to complete SCOPE phase first

**WARNING ACTIONS** (if warnings exist but success = true):
- Display each warning message to the user
- If session_status = "plan_exists": Ask for confirmation: "This session appears to already have plan content. Type 'overwrite' to proceed or 'review' to examine existing plan first."
- Only proceed to Phase 1 if user confirms appropriately

---

## PHASE 1: LEARNING SEQUENCE DESIGN & SUMMARY

**1.1. Comprehensive Topic Analysis**
- Review `learning-spec.md` for topics to include/exclude and detailed scope
- Break down broad topics into specific, learnable subtopics
- Identify natural topic clusters and learning dependencies
- Consider user's background knowledge and previous experience from specification

**1.2. Dependency Mapping & Sequencing**
- Analyze topic dependencies (prerequisites, building concepts)
- Map optimal learning sequence based on difficulty progression
- Plan logical progression from foundational to advanced concepts

**1.3. Learning Sequence Proposal and User Interaction**
- STOP and present detailed learning sequence, and ASK USER for sequence feedback.
  Then, WAIT for user feedback and adjust sequence accordingly

  ```
  Based on your specification, I've broken down {TOPIC} into these specific subtopics:
  
  [List all specific subtopics/concepts identified]

  I suggest organizing your learning into these phases:
  **Phase 1 - [Name]**: [specific topics and rationale for foundational learning]
  **Phase 2 - [Name]**: [specific topics and rationale building on Phase 1]  
  **Phase 3 - [Name]**: [specific topics and rationale for advanced concepts]
  **Phase N - [Name]**: [continue for all identified phases]

  Does this topic breakdown and learning sequence work for you?
  ```

**1.4. Learning Sequence Summary Generation**
- After receving the confirmation, finalize learning phases 
- **IMMEDIATELY** update `learning-plan.md` with results while context is fresh
  - **Template section to populate**: `### Learning Sequence Summary`
  - **Content format**: Use bullet points with phase names and brief descriptions following template example (You should follow the instructions in the template)
- **Quality assurance**: Verify learning sequence summary accurately reflects user-confirmed progression

**Phase 1 Output:**
- Complete list of specific learning subtopics identified
- Finalized learning sequence with user-confirmed phases and dependencies
- Phase names and progression logic established
- **Learning Sequence Summary section populated** in learning-plan.md
- Ready for phase framework generation

---

## PHASE 2: LEARNING PHASE FRAMEWORK GENERATION

**2.1. Learning Phase Structure Creation**
- Using the finalized learning sequence from Phase 1, generate empty phase framework
- Create all learning phase headings in the template
- Establish the structural foundation for detailed content filling

**2.2. Dynamic Phase Generation**
- For each learning phase identified in Phase 1:
  * Generate `### Learning Phase N: [Phase Name]` heading
  * Create empty subsection structure:
    - `#### Contents` (empty, to be filled in Phase 3 for each individual phase)
    - `#### Resources` (empty, to be filled in Phase 3 for each individual phase)  
    - `#### Checkpoints` (empty, to be filled in Phase 3 for each individual phase)
    - `#### Knowledge Vault Integration` (empty, to be filled in Phase 3 for each individual phase)

**2.3. Phase Framework Presentation**
- STOP and REPORT to user:

  ```
  I've created the learning phase framework based on your confirmed sequence. Please review it. This framework is now ready for detailed content development. Does this phase structure look correct?

  ### Learning Phase 1: [Phase Name]
  ### Learning Phase 2: [Phase Name]
  ...

  ```

- Receive the feedback from user. If approved, move to 2.4. If not, adjust according to the user's feedback

**2.4. Framework Template Update**
- **IMMEDIATELY** update `learning-plan.md` with the generated phase framework
- **Template section to populate**: `## Learning Plan` section
- Add all learning phase headings and empty subsections following template format
- **Quality assurance**: Verify all phases from Phase 1 are represented with correct structure

**Phase 2 Output:**
- Complete learning phase framework generated in template
- All phase headings and subsection structure created
- Empty sections ready for systematic content filling
- **Learning Plan section populated** with phase framework in learning-plan.md
- Ready for detailed content development

---

## PHASE 3: COMPLETE PHASE-BY-PHASE DEVELOPMENT

**3.1. Phase Development Overview**
- Work through each learning phase systematically to complete ALL aspects of each phase
- For each phase: Contents → Resources → Vault Integration → Checkpoints → User Review
- Ensure each phase is fully complete and actionable before moving to the next
- Maintain learning progression and build on previous phases

**3.2. Individual Phase Complete Development (Iterative Process)**
For each learning phase created in Phase 2, follow this comprehensive workflow:

**3.2.1. Phase Content Definition**
- Review the phase name and position in learning sequence
- Map specific subtopics from Phase 1 analysis to this phase
- Consider learning progression from completed previous phases
- Create clear, actionable learning objectives for this phase
- Follow template format: bullet list of learning contents

**3.2.2. Phase Resource Allocation**
- Review available resources from `resources.md`
- Consider the specific learning objectives just defined for this phase
- Select appropriate resources that support this phase's content
- Align resources with phase learning depth and complexity

**3.2.3. Phase Vault Integration Planning**
- Plan specific note organization for this phase's content
- Consider naming conventions and vault structure
- Plan wikilinks and connections to existing content and previous phases
- Align with overall MOC strategy (to be established in Phase 4)
- Follow vault naming conventions and organization patterns

**3.2.4. Phase Checkpoint Creation**
- Design specific, measurable checkpoints for this phase
- Consider the content, resources, and vault integration just planned
- Create completion criteria that validate learning objectives
- Focus on knowledge milestones and practical demonstrations
- Use checkbox format following template examples

**3.2.5. Complete Phase Presentation and User Review**
- STOP and REPORT complete phase to user:

  ```
  Complete development for [Phase N: Phase Name]:
  
  #### Contents
  - [Learning objective 1]
  - [Learning objective 2]
  - [Continue for all objectives...]
  
  #### Resources
  - [Resource type]: [Specific resource with details]
  - [Resource type]: [Specific resource with details]
  - [Continue for all resources...]
  
  #### Knowledge Vault Integration
  [Note organization plan for this phase]
  
  #### Checkpoints
  - [ ] [Checkpoint 1: Specific completion criteria]
  - [ ] [Checkpoint 2: Knowledge milestone]
  - [ ] [Continue for all checkpoints...]
  
  This phase is now complete and ready for learning. Does everything look good for this phase?
  ```

- WAIT for user feedback and adjust any aspect of the phase
- Allow user to modify content, resources, vault integration, or checkpoints
- **REVISION DETECTION**: If user requests changes to earlier phases (Phase 1 sequence or Phase 2 framework), follow "Revision and Backtracking Handling" procedures
- Ensure user approval of the complete phase before moving to template update

**3.2.6. Complete Phase Template Update**
- **IMMEDIATELY** update ALL sections for this phase in learning-plan.md:
  - `#### Contents` section with user-approved learning objectives
  - `#### Resources` section with user-approved resource allocation
  - `#### Knowledge Vault Integration` section with user-approved organization plan
  - `#### Checkpoints` section with user-approved completion criteria
- Follow template format instructions for all sections
- Ensure all sections reflect user-approved phase design

**3.3. Phase Development Iteration**
- Repeat steps 3.2.1-3.2.6 for each learning phase in sequence
- Work through Phase 1 completely, then Phase 2 completely, then Phase 3 completely, etc.
- Each phase builds on the knowledge and plan of completed previous phases
- Maintain consistency in quality while allowing each phase to have appropriate depth

**3.4. Overall Phase Development Review**
- After all individual phases are completely developed and approved:
- STOP and Ask user for final plan confirmation: "All learning phases are now complete. Please review the entire learning plan. Is everything ready for your learning journey?"
- Make any final cross-phase adjustments based on user feedback

**3.5. Complete Development Completion**
- Verify all sections for all phases are populated in learning-plan.md
- Ensure all sections follow template format requirements
- Confirm logical progression and coherence across completed phases
- **Quality assurance**: All phases are completely developed and user-approved

**Phase 3 Output:**
- ALL phases completely developed with Contents, Resources, Vault Integration, and Checkpoints
- Each phase fully approved by user as complete and actionable
- Logical progression established across all phases
- Template format compliance verified across all sections
- Ready for final plan validation and completion

---

## PHASE 4: PLAN COMPLETION & VALIDATION

**4.1. Overall MOC Strategy Development**
- STOP and ASK USER about their MOC approach:

  ```
  Now that all learning phases are complete, how would you like to organize this content in your knowledge vault?
  
  A) Use an existing MOC (please specify which one)
  B) Create a new MOC for this learning topic
  C) Other approach (please describe)
  ```

- WAIT for user response and clarify their vault organization preference
- Based on user choice, plan the overall MOC strategy and approach

**4.2. MOC Strategy Template Update**
- **IMMEDIATELY** update `### Knowledge Vault Integration Strategy` section in learning-plan.md
- Document chosen MOC approach (existing/new), MOC structure, and related vault contents
- Follow template format instructions for vault integration strategy

**4.3. Progress Tracking Initialization**
- **IMMEDIATELY** update `### Overall Learning Progress Tracking` section in learning-plan.md
- List all learning phases with "Pending" status
- Set Phase 1 as ready to begin when user starts STUDY phase
- Follow template format instructions for progress tracking structure

**4.4. Final Plan Validation**
- Verify all template sections are populated correctly
- Ensure no sections remain empty or with placeholder content
- Confirm logical progression and coherence across all phases
- Validate template format compliance across all sections

**4.5. Final Plan Presentation**
- STOP and REPORT complete plan to user:

  ```
  Plan phase is now complete! Here's what has been created:

  Learning Sequence: [Number] phases with clear progression
  Complete Phase Development: All aspects defined for each phase
  Knowledge Vault Strategy: Organization approach established
  Progress Tracking: System ready for learning execution

  The learning-plan.md file now contains your complete learning plan and is ready for the STUDY phase.

  Please review the complete plan. Is everything ready for you to begin learning?
  ```

**4.6. User Final Approval and Completion**
- WAIT for user final approval of complete plan
- Address any final adjustments or concerns
- **IMMEDIATELY STOP** all execution after user approval
- **DO NOT** proceed to study phase or any other activities
- **DO NOT** automatically run next learning commands
- Wait for explicit user instruction to proceed to STUDY phase

**4.7. Next Steps Guidance**
- Explain that the plan phase is complete
- Tell user they can now proceed to the STUDY phase when ready
- Note that the learning-plan.md file contains the complete blueprint
- Provide guidance on how to begin the learning execution

**Phase 4 Output:**
- MOC strategy established and documented
- Progress tracking system initialized
- Complete plan validation performed
- User final approval obtained
- Plan phase officially completed

---

## Integration with Vault Standards
- **MANDATORY**: Follow all `AGENTS.md` specifications for frontmatter, wikilinks, file naming, and content structure
- **Frontmatter**: Include required `parent` field, preserve existing `tags`, use proper wikilink syntax with quotes
- **File Naming**: Use "Broader Concept + Specific Topic" pattern, Title Case, avoid special characters. Do not include "MOC" in the filename (e.g., use `React.md` instead of `React MOC.md`).
- **MOC Integration**: Follow flat organization with wikilinks, maintain bidirectional connections
- **Content Structure**: One H1 heading matching filename, sequential heading levels (##, ###, ####), no task lists or emojis

## Error Handling
- If prerequisites fail, provide specific remediation steps
- If vault search fails, ask user for manual MOC identification
- If user responses are unclear, ask follow-up questions
- Never proceed with incomplete structural decisions

## Revision and Backtracking Handling
*Critical for maintaining plan integrity when users want to revise earlier decisions*

**When User Requests Changes to Previously Approved Phases:**
- **IMMEDIATELY STOP** current phase work and assess revision scope
- **CONFIRM IMPACT** with user using this exact pattern:

  ```
  You want to revise [specific element] from [Phase X]. This change will require:
  
  - Regenerating: [list affected subsequent phases and sections]
  - Re-approval: [list phases that need user review again]
  - Template updates: [list sections that will be overwritten]
  
  This means we'll need to restart from [Phase X] and work forward again.
  Are you sure you want to make this revision?
  ```

**Revision Scenarios and Actions:**
- **Phase 1 (Learning Sequence) changes**: Requires regenerating Phase 2 framework and ALL Phase 3 development
- **Phase 2 (Framework) changes**: Requires regenerating affected Phase 3 sections for modified phases
- **Individual Phase 3 changes**: Only affects that specific phase, can continue with remaining phases
- **Phase 4 (MOC Strategy) changes**: Can be revised without affecting other phases

**Revision Execution:**
- After user confirms revision, **IMMEDIATELY** update affected template sections
- Restart from the revised phase and work forward systematically
- Re-obtain user approval for all regenerated content
- Maintain quality standards equivalent to original development

## CONTINUOUS VALIDATION PRINCIPLES
*Apply throughout all phases*

- **AGENTS.md Compliance**: All actions must follow the vault standards, organization patterns, and agent behavior requirements specified in `AGENTS.md`
- **User Knowledge First**: Always ask users about their existing organization and preferences before searching or analyzing the vault
- **Never Assume**: If ANY structural aspect becomes unclear during execution, **IMMEDIATELY STOP and ASK USER** for clarification
- **Conditional Tool Usage**: Only use search tools when users explicitly request help or indicate uncertainty about their vault organization
- **Handle Ambiguity Constructively**: When users respond with "I don't know" about organization preferences, provide informed recommendations based on vault patterns with clear rationale
- **Vault-First Integration**: Always prioritize consistency with existing vault organization over abstract ideals, following MOC patterns and wikilink standards from `AGENTS.md`
- **User-Aligned Decisions**: All structural choices must align with user's stated preferences, constraints, and vault patterns
- **Progressive Disclosure**: Present structural decisions in logical order - don't overwhelm with all choices at once
- **Validate Alignment**: Before populating each major section, confirm the approach matches user expectations and vault integration needs
- **Escalation Strategy**: If uncertainty persists about vault integration, ask user to show examples from their existing vault organization

---

## Success Criteria
- Prerequisites validation passes
- Complete topic analysis with specific subtopics and learning sequence (Phase 1)
- **Learning-plan.md learning plan sections populated immediately** (Phase 1)
- **Complete learning phase framework** with empty plan ready for development (Phase 2)
- **Learning-plan.md phase framework populated immediately** (Phase 2)
- **Complete phase-by-phase development** with all aspects filled for each individual phase (Phase 3)
- **Learning-plan.md all phase sections populated immediately** during Phase 3 development (Phase 3)
- Comprehensive validation and integration check completed (Phase 4)
- **Complete learning-plan.md ready for STUDY phase** with all sections populated progressively
- Ready for post-PLAN MOC creation/modification
- All planned outputs follow AGENTS.md frontmatter, naming, and content structure requirements

---

## Integration with Learning System

**Command Parameters:** SESSION_IDENTIFIER (full path, session name, topic name, or partial match)
**Prerequisites:** Completed SCOPE phase with learning-spec.md and resources.md in target session
**Session Discovery:** Uses find-learning-session.sh script for intelligent session identification and disambiguation
**Outputs:** Fully populated learning-plan.md with comprehensive learning phases, MOC strategy, and progress tracking
**Next Steps:** Ready for STUDY phase execution with learning-study command
**Continuity:** Builds on SCOPE phase outputs and prepares for STUDY phase interactive learning