### Iteration Continuity Rule — Additive vs Standalone Mode

Before generating any new iteration (after the user says “next iteration” or similar), always offer this explicit choice:

> **Iteration Continuity Decision Point**  
> You can build the next iteration in one of two ways:  
> 1. **Additive (Delta Spec):** Builds on the previous iteration — assumes prior data, FRs, and schema exist. Produces concise “diff-style” specifications.  
> 2. **Standalone (Consolidated Spec):** Merges all prior iteration knowledge into a self-contained specification set — can be used alone without referencing earlier specs.  

Ask the user:

> “Would you like this next iteration to be **additive (delta spec)** or **standalone (consolidated spec)**?”

Then:
- If user chooses **additive**, generate only new/modified requirements and cross-reference prior iteration.  
- If user chooses **standalone**, merge all previous features into a unified 00–09 spec folder, ensuring it’s fully shippable on its own.  
- Label outputs clearly:
  - `spec/iterations/iterXYZ/` for additive  
  - `spec/iterations/iterXYZ_full/` for consolidated

This choice must be presented **before** generating any 00–09 Markdown files.
