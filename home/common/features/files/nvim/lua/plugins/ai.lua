return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp",
  },
  config = function()
    require("codecompanion").setup({
      strategies = {
        chat = { adapter = "ollama" },
        inline = { adapter = "ollama" },
        agent = { adapter = "ollama" },
      },
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = { default = "gemma3" },
            },
          })
        end,
      },
      prompt_library = {
        ["Corrector Gramatical"] = {
          strategy = "inline",
          description = "Corrige la gramática y ortografía del texto seleccionado",
          opts = {
            index = 1,
            is_slash_cmd = true,
            short_name = "gramatica",
            auto_submit = true,
          },
          prompts = {
            {
              role = "system",
              content = "Eres un experto editor lingüístico. Corrige errores gramaticales y ortográficos.",
            },
            {
              role = "user",
              content = function(context)
                local text = table.concat(context.lines, "\n")
                return "Por favor, corrige el siguiente texto: \n\n" .. text
              end,
            },
          },
        },
        ["Traductor Alemán"] = {
          strategy = "inline",
          description = "Traduce el texto al alemán",
          opts = {
            index = 2,
            is_slash_cmd = true,
            short_name = "deu",
            auto_submit = true,
          },
          prompts = {
            {
              role = "system",
              content = "Eres un traductor profesional. Traduce de forma natural al alemán.",
            },
            {
              role = "user",
              content = function(context)
                local text = table.concat(context.lines, "\n")
                return "Traduce esto al alemán: \n\n" .. text
              end,
            },
          },
        },
        ["Analista de texto"] = {
          strategy = "chat",
          description = "Interpreta el siguiente texto.",
          opts = {
            index = 2,
            is_slash_cmd = true,
            short_name = "why",
            auto_submit = true,
          },
          prompts = {
            {
              role = "system",
              content =
              "USA ESPAÑOL PARA LAS RESPUESTAS. Eres un profesor de Español y Literatura. Realiza un análisis detallado del texto dado en español.",
            },
            {
              role = "user",
              content = function(context)
                local text = table.concat(context.lines, "\n")
                return "Interpreta el siguiente texto: \n\n" .. text
              end,
            },
          },
        },
      },
    })
  end,
}
