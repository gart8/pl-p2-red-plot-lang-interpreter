Red [Needs: 'View]

tree-canvas-width: 860
tree-canvas-height: 540

cell-index: func [x [integer!] y [integer!] width [integer!] height [integer!]][
    1 + x + ((height - 1 - y) * width)
]

cell-value: func [cells [block!] x [integer!] y [integer!] width [integer!] height [integer!]][
    pick cells cell-index x y width height
]

set-cell: func [cells [block!] x [integer!] y [integer!] value [integer!] width [integer!] height [integer!]][
    if all [x >= 0 x < width y >= 0 y < height][
        poke cells cell-index x y width height value
    ]
]

coordinate-values: func [coordinate [string!]][
    coordinate: compact-coordinate trim coordinate
    letter-position: find valid-letters to-string coordinate/1
    if none? letter-position [return [0 0]]
    reduce [index? letter-position to-integer to-string coordinate/2]
]

absolute-integer: func [value [integer!]][
    if value < 0 [value: 0 - value]
    value
]

mark-bar: func [cells [block!] plot [block!] width [integer!] height [integer!]][
    point: coordinate-values plot/2
    start-x: point/1 - 1
    top-y: point/2
    bar-width: to-integer plot/3
    repeat x-offset bar-width [
        repeat y-value top-y [
            set-cell cells start-x + x-offset - 1 y-value - 1 1 width height
        ]
    ]
]

mark-line: func [cells [block!] plot [block!] width [integer!] height [integer!]][
    start: coordinate-values plot/2
    finish: coordinate-values plot/3
    start-x: start/1 - 1
    finish-x: finish/1 - 1
    delta-x: finish-x - start-x
    delta-y: finish/2 - start/2
    steps: max absolute-integer delta-x absolute-integer delta-y
    if steps = 0 [set-cell cells start-x start/2 1 width height return true]
    repeat step steps + 1 [
        ratio: (step - 1) / steps
        x: to-integer (start-x + (delta-x * ratio) + 0.5)
        y: to-integer (start/2 + (delta-y * ratio) + 0.5)
        set-cell cells x y 1 width height
    ]
]

flood-fill: func [cells [block!] start-x [integer!] start-y [integer!] width [integer!] height [integer!]][
    if any [start-x < 0 start-x >= width start-y < 0 start-y >= height][return true]
    target: cell-value cells start-x start-y width height
    replacement: 2
    if target = replacement [return true]
    queue: copy [0x0]
    queue/1: as-pair start-x start-y
    set-cell cells start-x start-y replacement width height
    while [not empty? queue][
        point: take queue
        neighbors: reduce [
            as-pair point/x + 1 point/y
            as-pair point/x - 1 point/y
            as-pair point/x point/y + 1
            as-pair point/x point/y - 1
        ]
        foreach neighbor neighbors [
            if all [
                neighbor/x >= 0 neighbor/x < width
                neighbor/y >= 0 neighbor/y < height
                (cell-value cells neighbor/x neighbor/y width height) = target
            ][
                set-cell cells neighbor/x neighbor/y replacement width height
                append queue neighbor
            ]
        ]
    ]
]

fill-bar: func [cells [block!] shape [block!] width [integer!] height [integer!]][
    start-x: shape/1
    start-y: shape/2
    bar-width: shape/3
    bar-height: shape/4
    repeat x-offset bar-width [
        repeat y-offset bar-height [
            set-cell cells (start-x + x-offset - 1) (start-y - y-offset) 2 width height
        ]
    ]
]

bar-containing-point: func [shapes [block!] point [block!]][
    foreach shape shapes [
        if all [
            ((point/1 - 1) >= shape/1)
            ((point/1 - 1) < (shape/1 + shape/3))
            (point/2 <= shape/2)
            (point/2 >= (shape/2 - shape/4))
        ][return copy shape]
    ]
    none
]

draw-graph: func [][
    width: 10
    height: 9
    bar-colors: [255.179.186 255.223.186 255.255.186 186.255.201 186.225.255]
    line-colors: [red blue black green]
    bar-number: 0
    line-number: 0
    foreach plot plots [
        if plot/1 = "grid" [
            grid-point: coordinate-values plot/2
            width: grid-point/1 - 1
            height: grid-point/2
        ]
    ]
    if width < 1 [width: 1]
    if height < 1 [height: 1]
    cell-size: to-integer 630 / width
    if (400 / height) < cell-size [cell-size: to-integer 400 / height]
    cell-width: cell-size
    cell-height: cell-size
    origin: 50x430
    cells: copy []
    loop width * height [append cells 0]
    bar-shapes: copy []
    line-shapes: copy []
    filled-shapes: copy []
    grid-visible?: false
    foreach plot plots [
        command: plot/1
        if command = "grid" [grid-visible?: true]
        if command = "bar" [
            point: coordinate-values plot/2
            bar-number: bar-number + 1
            bar-color: pick bar-colors 1 + ((bar-number - 1) // length? bar-colors)
            shape: reduce [(point/1 - 1) point/2 (to-integer plot/3) point/2 bar-color]
            append/only bar-shapes shape
            mark-bar cells plot width height
        ]
        if command = "line" [
            mark-line cells plot width height
            start-point: coordinate-values plot/2
            end-point: coordinate-values plot/3
            line-number: line-number + 1
            line-color: pick line-colors 1 + ((line-number - 1) // length? line-colors)
            append/only line-shapes reduce [(start-point/1 - 1) start-point/2 (end-point/1 - 1) end-point/2 line-color]
        ]
    ]
    foreach plot plots [
        if plot/1 = "fill" [
            point: coordinate-values plot/2
            selected-shape: none
            foreach candidate bar-shapes [
                if all [
                    ((point/1 - 1) >= candidate/1)
                    ((point/1 - 1) < (candidate/1 + candidate/3))
                    (point/2 <= candidate/2)
                    (point/2 >= (candidate/2 - candidate/4))
                ][selected-shape: copy candidate]
            ]
            if none? selected-shape [
                flood-fill cells point/1 - 1 point/2 width height
            ]
            if not none? selected-shape [
                append/only filled-shapes selected-shape
            ]
        ]
    ]
    draw-block: copy [pen gray]
    repeat y height [
        repeat x width [
            state: cell-value cells x - 1 y - 1 width height
            if state = 2 [
                top-left: as-pair origin/x + ((x - 1) * cell-width) + 1 origin/y - (y * cell-height) + 1
                bottom-right: as-pair origin/x + (x * cell-width) - 1 origin/y - ((y - 1) * cell-height) - 1
                append draw-block reduce ['fill-pen gold 'box top-left bottom-right]
            ]
        ]
    ]
    foreach shape filled-shapes [
        left: origin/x + ((shape/1) * cell-width)
        right: left + ((shape/3) * cell-width)
        top: origin/y - ((shape/2) * cell-height)
        bottom: origin/y
        append draw-block reduce [
            'fill-pen shape/5
            'box as-pair left + 1 top + 1 as-pair right - 1 bottom - 1
        ]
    ]
    if grid-visible? [
        repeat x width + 1 [
            x-position: origin/x + ((x - 1) * cell-width)
            append draw-block reduce ['pen gray 'line as-pair x-position origin/y as-pair x-position origin/y - (height * cell-height)]
        ]
        line-count: height + 1
        repeat y line-count [
            y-position: origin/y - ((y - 1) * cell-height)
            append draw-block reduce ['pen gray 'line as-pair origin/x y-position as-pair origin/x + (width * cell-width) y-position]
        ]
        repeat x width + 1 [
            label: to-string pick valid-letters x
            append draw-block reduce ['text as-pair origin/x + ((x - 1) * cell-width) + 5 origin/y + 30 label]
        ]
        repeat y height + 1 [
            append draw-block reduce ['text as-pair 20 origin/y - ((y - 1) * cell-height) + 5 to-string (y - 1)]
        ]
    ]
    foreach shape bar-shapes [
        left: origin/x + ((shape/1) * cell-width)
        right: left + ((shape/3) * cell-width)
        top: origin/y - ((shape/2) * cell-height)
        bottom: origin/y
        append draw-block reduce [
            'line-width 3
            'pen black
            'line as-pair left top as-pair right top
            'line as-pair right top as-pair right bottom
            'line as-pair right bottom as-pair left bottom
            'line as-pair left bottom as-pair left top
        ]
    ]
    foreach shape line-shapes [
        start-x: origin/x + ((shape/1) * cell-width)
        start-y: origin/y - ((shape/2) * cell-height)
        end-x: origin/x + ((shape/3) * cell-width)
        end-y: origin/y - ((shape/4) * cell-height)
        append draw-block reduce [
            'line-width 3
            'pen shape/5
            'line as-pair start-x start-y as-pair end-x end-y
        ]
    ]
    draw-block
]

draw-output: func [][
    view layout [
        title "Red Plot Language - Graph Output"
        backdrop snow
        panel 1200x900 [
            below
            text "Graph output" font-size 18
            canvas: base 1200x900 white draw draw-graph
        ]
    ]
]

tree-leaf: func [label [string!]][reduce [label copy []]]

tree-coordinate: func [coordinate [string!] /local node][
    coordinate: compact-coordinate coordinate
    node: reduce ["<x><y>" copy []]
    append/only node/2 tree-leaf to-string coordinate/1
    append/only node/2 tree-leaf to-string coordinate/2
    node
]

tree-plot: func [plot [block!] /local node][
    node: reduce ["<plot>" copy []]
    append/only node/2 tree-leaf plot/1
    append/only node/2 tree-coordinate plot/2
    if plot/1 = "bar" [
        append/only node/2 tree-leaf ","
        append/only node/2 reduce ["<y>" reduce [tree-leaf to-string plot/3]]
    ]
    if plot/1 = "line" [
        append/only node/2 tree-leaf ","
        append/only node/2 tree-coordinate plot/3
    ]
    node
]

parse-tree-model: func [/local statements plot-index plot-count][
    statements: copy []
    plot-index: 1
    plot-count: length? plots
    foreach plot plots [
        append/only statements tree-plot plot
        if plot-index < plot-count [append/only statements tree-leaf ";"]
        plot-index: plot-index + 1
    ]
    reduce [
        "<graph>"
        reduce [
            ["start" []]
            reduce ["<plot_stmts>" statements]
            ["end" []]
        ]
    ]
]

tree-leaf-count: func [node [block!] /local total child][
    if all [(length? node) = 1 or empty? node/2][return 1]
    total: 0
    foreach child node/2 [total: total + tree-leaf-count child]
    total
]

tree-depth: func [node [block!] /local deepest child child-depth][
    if all [(length? node) = 1 or empty? node/2][return 0]
    deepest: 0
    foreach child node/2 [
        child-depth: tree-depth child
        if child-depth > deepest [deepest: child-depth]
    ]
    deepest + 1
]

tree-layout-node: func [node [block!] state [object!] depth [integer!] /local layout-node child total][
    layout-node: make object! [
        label: node/1
        x: 0
        y: 20
        width: 90
        children: copy []
    ]
    layout-node/y: 20 + (depth * state/y-step)
    layout-node/width: state/node-width
    if (length? node) > 1 [
        foreach child node/2 [
            append/only layout-node/children tree-layout-node child state (depth + 1)
        ]
    ]
    if empty? layout-node/children [
        layout-node/x: state/next-x
        state/next-x: state/next-x + state/x-step
    ]
    if not empty? layout-node/children [
        total: 0
        foreach child layout-node/children [total: total + child/x]
        layout-node/x: total / (length? layout-node/children)
    ]
    layout-node
]

tree-draw-lines: func [node [object!] draw-block [block!] /local child][
    foreach child node/children [
        append draw-block reduce [
            'line as-pair node/x (node/y + 28) as-pair child/x child/y
        ]
        tree-draw-lines child draw-block
    ]
]

tree-draw-nodes: func [node [object!] draw-block [block!] /local left child][
    left: node/x - (node/width / 2)
    append draw-block reduce [
        'fill-pen white
        'pen black
        'box as-pair left node/y as-pair left + node/width node/y + 28
        'text as-pair left + 6 node/y + 7 node/label
    ]
    foreach child node/children [tree-draw-nodes child draw-block]
]

parse-tree-draw: func [/local state root draw-block model leaf-count depth x-step box-width][
    model: parse-tree-model
    leaf-count: tree-leaf-count model
    depth: tree-depth model
    x-step: 28
    box-width: 35
    tree-canvas-width: max 1900 ((leaf-count * x-step) + 80)
    tree-canvas-height: max 540 ((depth + 1) * 65 + 60)
    state: make object! [next-x: 0 x-step: 0 y-step: 0 node-width: 0]
    state/next-x: 30
    state/x-step: x-step
    state/y-step: 65
    state/node-width: box-width
    root: tree-layout-node model state 0
    draw-block: copy [line-width 1]
    tree-draw-lines root draw-block
    tree-draw-nodes root draw-block
    draw-block
] 


show-parse-tree-window: func [/local draw-block window-size canvas-size][
    draw-block: parse-tree-draw
    window-size: as-pair (tree-canvas-width + 60) (tree-canvas-height + 80)
    canvas-size: as-pair tree-canvas-width tree-canvas-height
    view layout [
        title "Red Plot Language - Parse Tree"
        backdrop snow
        panel window-size [
            below
            text "Parse Tree" font-size 12
            tree: base canvas-size white draw draw-block
        ]  
    ]
]
