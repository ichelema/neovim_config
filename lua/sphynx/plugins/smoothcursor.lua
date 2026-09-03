--[[
===============================================================================================
Plugin: SmoothCursor.nvim
===============================================================================================
Descrizione: Aggiunge un effetto di sotto-cursore colorato in Neovim che mostra la direzione
             del movimento
Status: Attivo
Autore: Gen Fujimoto
Repository: https://github.com/gen740/SmoothCursor.nvim
Note:
 - Utilizza la modalità fancy con una scia di cursori personalizzati
 - Configurato per mostrare una scia di cursori di dimensioni decrescenti con colori ambrati
 - Disabilitato nelle finestre flottanti per evitare interferenze visive
 - Disabilitato in TelescopePrompt, NvimTree, dashboard e lazy per evitare conflitti
 - Soglia di movimento impostata a 3 linee (l'animazione si attiva solo per salti > 3 linee)
 - Soglia massima di 40 linee per evitare animazioni durante salti molto lunghi
 - Intervallo di aggiornamento di 35ms e velocità di animazione di 25 (velocità moderata)
 - Timeout dell'animazione di 3000ms per evitare effetti persistenti
 - Effetto "flyin" impostato a "bottom" per un'animazione dal basso verso l'alto

Dettagli di Configurazione:
 - cursor: ""              → Forma personalizzata del cursore (richiede Nerd Font)
 - fancy.enable: true      → Abilita la modalità fancy con effetto di scia
 - fancy.head.cursor: ""  → Carattere per il cursore principale
 - fancy.body: {...}       → Serie di cursori di scia con forme e colori diversi
   - Gradiente di colori ambrati da #9E7741 a #0F0B06
   - Le forme dei cursori diminuiscono di dimensione: ● → ● → • → • → . → .
 - type: "exp"            → Calcolo della traiettoria di tipo esponenziale per movimento più naturale
 - speed: 25               → Velocità dell'animazione (max 100)
 - intervals: 35           → Frequenza di aggiornamento in millisecondi
 - threshold: 3            → Numero minimo di linee da saltare prima che l'animazione si attivi
 - max_threshold: 40       → Numero massimo di linee oltre il quale l'animazione viene disabilitata
 - priority: 10            → Priorità di visualizzazione per i marcatori del cursore
 - timeout: 3000           → Durata massima dell'animazione in millisecondi
 - flyin_effect: "bottom"  → Effetto di volo dal basso verso l'alto
 - disable_float_win: true → Disabilita l'effetto nelle finestre flottanti
 - disabled_filetypes: {"TelescopePrompt", "NvimTree", "dashboard", "lazy"}
                          → Impedisce l'attivazione in specifici tipi di file

Comandi:
 - :SmoothCursorStart       → Avvia l'effetto del cursore fluido
 - :SmoothCursorStop        → Ferma l'effetto del cursore fluido
 - :SmoothCursorToggle      → Attiva/disattiva l'effetto
 - :SmoothCursorStatus      → Controlla se il cursore fluido è attivo
 - :SmoothCursorFancyToggle → Attiva/disattiva la modalità fancy
 - :SmoothCursorFancyOn     → Attiva la modalità fancy
 - :SmoothCursorFancyOff    → Disattiva la modalità fancy
 - :SmoothCursorDeleteSigns → Rimuove tutti i segni del cursore

Strategia di Caricamento:
 - Caricato in modo lazy tramite eventi nativi lazy.nvim su apertura file

TODO:
 - [ ] Testare il tipo "matrix" per un effetto visivo alternativo
 - [ ] Valutare l'impatto sulle prestazioni con diversi valori di soglia
 - [x] Considerare l'integrazione con temi di colore scuri per una migliore visibilità
============================================================================================
]]

local M = {}

M.plugins = {
    ["smoothcursor"] = {
        "gen740/SmoothCursor.nvim",
        lazy = true,
        event = { "BufReadPost", "BufNewFile" },
    },
}


M.configs = {
    ["smoothcursor"] = function()
        require("smoothcursor").setup({
            autostart = true,
            cursor = "", -- cursor shape (need nerd font)
            texthl = "SmoothCursor", -- highlight group, default is { bg = nil, fg = "#FFD400" }
            linehl = nil, -- highlight sub-cursor line like 'cursorline', "CursorLine" recommended
            type = "exp", -- define cursor movement calculate function, "default" or "exp" (exponential).
            fancy = {
                enable = true, -- enable fancy mode
                head = { cursor = "", texthl = "SmoothCursor", linehl = nil },
                body = {
                    { cursor = "●", texthl = "SmoothCursorTrail1" },
                    { cursor = "●", texthl = "SmoothCursorTrail2" },
                    { cursor = "•", texthl = "SmoothCursorTrail3" },
                    { cursor = "•", texthl = "SmoothCursorTrail4" },
                    { cursor = ".", texthl = "SmoothCursorTrail5" },
                    { cursor = ".", texthl = "SmoothCursorTrail6" },
                },
                tail = { cursor = nil, texthl = "SmoothCursor" },
            },
            flyin_effect = nil, -- "bottom" or "top"
            speed = 25, -- max is 100 to stick to your current position
            intervals = 35, -- tick interval
            priority = 10, -- set marker priority
            timeout = 1000, -- timout for animation
            threshold = 10, -- animate if threshold lines jump
            disable_float_win = true, -- disable on float window
            max_threshold = 200, -- If you move more than this many lines, don't animate
            enabled_filetypes = nil, -- example: { "lua", "vim" }
            disabled_filetypes = { "TelescopePrompt", "NvimTree", "dashboard", "lazy" },
        })
    end,
}

return M
