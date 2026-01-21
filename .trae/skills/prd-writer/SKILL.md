---
name: "prd-writer"
description: "Generates, optimizes, or reviews Product Requirement Documents (PRD) following strict standardization guidelines. Invoke when user asks to write a PRD or improve requirement docs."
---

# PRD Writer

This skill helps users write high-quality Product Requirement Documents (PRD) based on the "PRD Writing Standard" (PRD文档编写规范).

## Capabilities

1.  **Generate PRD**: Create a full PRD from a brief description.
2.  **Optimize PRD**: Refine existing PRD content to match the standard.
3.  **Review PRD**: Check if a PRD follows the standard and suggest improvements.

## PRD Structure Standard

A complete PRD MUST include:

1.  **Document Info**: Title, Version History, Background, Goal, Scope.
2.  **Roles & Workflows**: User Roles, Flowcharts (Mermaid/ProcessOn).
3.  **Functional Requirements** (Core):
    *   Function Name, Preconditions, Page/Entry.
    *   **UI/Prototype**: Layout, Field Definitions (Tabular format required).
    *   **Interaction**: Feedback, Exception Handling.
    *   **Backend Logic**: Data flow, Calculations, Side effects.
4.  **Non-functional Requirements**: Performance, Security, Stats, Compatibility.
5.  **Data Dictionary & Appendix**: ER Diagram, Enums, Global Rules.

## Key Rules

*   **Tabular Fields**: NEVER use text to describe fields. Use a table with columns: Field Name, Type, Required, Default, Validation, Remarks.
*   **Structured Logic**: Use "If... Then... Else..." for complex logic.
*   **Concrete Interaction**: Define exact feedback (Toast, Jump, Modal) and Error states.
*   **Language**: Output in Chinese (Simplified) unless requested otherwise.

## Template

Use this structure for new features:

```markdown
### {Module Name} Requirement

#### 1. {Function Name}
*   **Priority**: P0/P1
*   **User Role**: ...
*   **Description**: ...
*   **Prototype**: [Description or Link]
*   **Fields**:
    | Field | Type | Required | Default | Rule | Note |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | ... | ... | ... | ... | ... | ... |
*   **Logic**:
    1.  Step 1...
    2.  Step 2...
*   **Exceptions**: ...
```

## Instructions

*   When the user provides a feature idea, ask for clarification if the scope is too broad.
*   Always strictly follow the "Field Definition Table" rule.
*   Ensure "Version Record" is present for document updates.
