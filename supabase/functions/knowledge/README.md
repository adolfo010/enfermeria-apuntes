# Knowledge retrieval v1

Prototype endpoint for the new academic knowledge layer.

Actions:
- `searchConcepts`: search normalized concepts.
- `concept`: retrieve concept, children, aliases, relations and sources.
- `retrieve`: retrieve source fragments associated with concept IDs.

This function is isolated from the existing `drive` function and is not deployed by this branch work.

Security note: before production deployment, add authenticated-user validation and authorization/RLS enforcement.