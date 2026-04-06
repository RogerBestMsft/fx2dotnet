# Web Migration Checklist

Checklist for side-by-side ASP.NET Core host migration.

1. Confirm legacy web host project in scope.
2. Complete route, handler, and module inventory.
3. Identify auth and pipeline behaviors.
4. Scaffold new ASP.NET Core host side-by-side.
5. Port routes in small validated slices.
6. Validate route shape, verb, auth, and response contract per slice.
7. Keep legacy host intact until parity review is complete.
