# FocusPanel page contract

Each page is a self-contained QML **`Item`** loaded into the panel's content area
(right of the nav rail, ~715×600). File: `bar/pages/<Name>Page.qml`.

## Skeleton
```qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
// import Quickshell.Io   // only if the page itself spawns a Process

Item {
    id: page
    // ColumnLayout { anchors.fill: parent; anchors.margins: 18; ... }
}
```

## Services (all `import qs.services`, singletons)
- **Tasks** (read model, auto-refreshing):
  - `Tasks.all` → array of full taskwarrior objects (pending), sorted active-first then urgency.
    Fields per object: `id`(int), `description`(str), `project`(str?), `tags`(string[]?),
    `priority`("H"|"M"|"L"|undef), `due`(ISO string?), `scheduled`(?), `urgency`(num),
    `annotations`([{entry, description}]?), `start`(present ⇒ active block), `status`.
  - `Tasks.done` → completed task objects (last 21d).
  - `Tasks.projects` → `[{name, count}]` (pending, by project), count-desc.
  - `Tasks.tags` → `[{name, count}]`.
  - `Tasks.refresh()`.
- **TaskActions** (write; async — host bridge runs the command, snapshot re-exports,
  `Tasks.all` updates within ~1s, so the UI is reactive — no manual reload):
  - `add(desc, extraArgs[])`, `modify(id, fields[])`, `done(id)`, `remove(id)`,
    `annotate(id, text)`, `setProject(id, proj)`, `addTag(id, tag)`, `removeTag(id, tag)`,
    `setPriority(id, "H"|"M"|"L"|"")`, `setDue(id, "YYYY-MM-DD"|"tomorrow"|"")`,
    `cmd(argsArray)` (raw), `startBlock(idStr | "new:<desc>")`.
  - `fields`/`extraArgs` are taskwarrior arg strings, e.g. `["project:work","+urgent","due:friday"]`.
- **PanelState** (nav): `page`, `selectedTaskId`, `filterProject`, `filterTag`,
  `filterStatus`("pending"|"today"|"overdue"|"all"); `go("tasks")`, `openDetail(id)`.
- **Focus** (`running`, `blockMinutes`, `nextPrayerName`, `nextPrayerTime`),
  **ActiveTask** (`task`, `elapsed`, `active`), **Salah**, **BarState** (`closePalette()`).

## Theme (`Theme.*`)
Colors: `base bg fg comment surface0 surface1 surface2 subtext0 purple pink blue cyan
green orange red yellow glass glass2 s1 s2 bd hov ctxAccent`. Helper `Theme.withAlpha(c, a)`.
Fonts: **always `font.family: Theme.fontMono`**. Radii: `rad`(16) `pill`(99) `chip`(9).
Dracula palette. Priority colors: H=red, M=orange, L=cyan (suggested).

## Components (`import qs.components`)
- **StyledText** = a `Text` (set `text`, `color`, `font.family: Theme.fontMono`, `font.pixelSize`,
  `elide`). **StyledRect** = a `Rectangle`. Otherwise use plain QtQuick
  `Rectangle`/`MouseArea`/`Repeater`/`Flickable`/`ListView`/`TextInput`/`ColumnLayout`/`RowLayout`.

## Conventions
- Scrollable lists: `Flickable { contentHeight: col.implicitHeight; clip: true; ColumnLayout{...} }`
  or `ListView`. Cap nothing — let it scroll.
- Row hover highlight: `color: hovered ? Theme.withAlpha(Theme.purple,0.12) : "transparent"`.
- `Repeater` delegates need `required property var modelData` (+ `required property int index`).
- Buttons: a `Rectangle{radius;color;border}` + `StyledText` + `MouseArea{cursorShape:Qt.PointingHandCursor;onClicked}`.
- Mutations are fire-and-forget; do NOT block or await. The list updates itself.
- Keep the Dracula glass aesthetic: dark surfaces (`Theme.s1`/`s2`/`surface0`), subtle borders (`Theme.bd`).
