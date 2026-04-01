# Notes

## Open Issues

### MCP Server Integration with Spec-Kit Workflow

**Issue:** Getting the MCP server into the target (user's solution) is not working as expected.

A single extension with commands appears functional but operates independently of the Spec-Kit workflow — the two are not connected. The MCP server capabilities are not being surfaced through the Spec-Kit migration flow as intended. The question of whether this should be one extension or multiple is part of the unresolved integration problem.

**Impact:** Users going through the Spec-Kit-driven migration may not have MCP server tools available at the right phases.

**Status:** Under investigation.
