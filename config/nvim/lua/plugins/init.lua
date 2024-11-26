return {
    {
        "stevearc/conform.nvim",
        event = "BufWritePre", -- uncomment for format on save
        opts = require "configs.conform",
    },

    {
        "neovim/nvim-lspconfig",
        config = function()
            require "configs.lspconfig"
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "vim",
                "lua",
                "vimdoc",
                "html",
                "css",
                "htmldjango",
                "rust",
                "json",
                "javascript",
                "typescript",
                "python",
                "tsx",
            },
        },

        {
            "stevearc/dressing.nvim",
            lazy = false,
            opts = {},
        },

        {
            "mfussenegger/nvim-lint",
            event = "VeryLazy",
            config = function()
                require "configs.lint"
            end,
        },

        {
            "windwp/nvim-ts-autotag",
            event = "VeryLazy",
            config = function()
                require("nvim-ts-autotag").setup()
            end,
        },

        {
            "folke/trouble.nvim",
            lazy = false,
            dependencies = { "nvim-tree/nvim-web-devicons" },
        },

        {
            "folke/todo-comments.nvim",
            lazy = false,
            dependencies = { "nvim-lua/plenary.nvim" },
            config = function()
                require("todo-comments").setup()
            end,
        },

        {
            "Exafunction/codeium.vim",
            lazy = false,
        },

        {
            "rust-lang/rust.vim",
            ft = "rust",
            init = function()
                vim.g.rustfmt_autosave = 1
            end,
        },

        {
            "mrcjkb/rustaceanvim",
            version = "^5",
            lazy = false,
            ensure_installed = { "codelldb", "rust-analyzer" },
        },

        {
            "mfussenegger/nvim-dap",
            config = function()
                local dap, dapui = require "dap", require "dapui"
                dap.listeners.before.attach.dapui_config = function()
                    dapui.open()
                end
                dap.listeners.before.launch.dapui_config = function()
                    dapui.open()
                end
                dap.listeners.before.event_terminated.dapui_config = function()
                    dapui.close()
                end
                dap.listeners.before.event_exited.dapui_config = function()
                    dapui.close()
                end
            end,
        },

        {
            "rcarriga/nvim-dap-ui",
            dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
            config = function()
                require("dapui").setup()
            end,
        },

        {
            "saecki/crates.nvim",
            ft = { "toml" },
            config = function()
                require("crates").setup {
                    completion = {
                        cmp = {
                            enabled = true,
                        },
                    },
                }
                require("cmp").setup.buffer {
                    sources = { { name = "crates" } },
                }
            end,
        },

        {
            "luckasRanarison/tailwind-tools.nvim",
            name = "tailwind-tools",
            build = ":UpdateRemotePlugins",
            dependencies = {
                "nvim-treesitter/nvim-treesitter",
                "nvim-telescope/telescope.nvim",
                "neovim/nvim-lspconfig",
            },
            opts = {
                server = {
                    settings = {
                        includeLanguages = {
                            rust = "html",
                        },
                    },
                },
                extension = {
                    patterns = {
                        rust = { 'class: ["](.*)["]' },
                        javascript = { "className=['\"](.*)['\"]" },
                        typescript = { "className=['\"](.*)['\"]" },
                    },
                },
            },
        },
    },
}
