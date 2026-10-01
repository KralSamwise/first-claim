# Contributing to First Claim

Try the game, find something you would enjoy improving, and make a focused change. Art, gameplay, accessibility, documentation and platform testing are all welcome.

## Run and check

Use Godot 4.5.2 and import `project.godot`. Run the game from the editor with F5. To use the shell helpers, put `godot` on PATH or set `GODOT_BIN` to the Godot executable:

```sh
python3 tools/check_project.py
./tools/godot --headless --script tests/accounting.gd
./tools/godot --headless --script tests/json_identity.gd
./tools/godot --headless --script tests/saves_all_stages.gd
./tools/godot --headless --script tests/support.gd
```

On Windows, run the same commands using your Godot executable with `--path .` in place of `./tools/godot`. Tests write dedicated `test_` or `test-` save files, not the normal campaign slot. Back up your normal save before testing changes to persistence.

The Blender generators are optional. They rebuild source assets and can overwrite generated files, so run them on your own branch. Blender 4.5 was used for the original assets. Do not commit editor caches, engine binaries, recordings, personal saves or credentials.

## Submit a change

1. Fork the repository and create a branch for your change.
2. Explain the player-facing problem or idea.
3. Make a focused change, keeping unrelated work separate.
4. Run checks appropriate to the change and try it in the actual game.
5. Open a pull request with what changed, how you tested it, and a screenshot or short clip when useful.

Keep tests and real play observations distinct. A guided controller passing a route is useful evidence, but it cannot tell us whether a new player understands the game or enjoys the pacing.

For bugs, include your OS, Godot version, steps to reproduce, expected result and actual result. Remove personal information before attaching a save or log. For features, describe the experience you want rather than only the implementation.

Only contribute work you have the right to share. Explain the source and license of new assets. Contributions to original project material are under the repository's MIT license. AI-assisted contributions are welcome; describe the assistance and verify the result yourself.
