return {
    "mason-org/mason-lspconfig.nvim",
    opts = {
    	ensure_installed = {
    		"lua_ls",
        "bashls",
        "cmake",
        "dockerls",
        "gitlab_ci_ls",
        "jsonls",
        "pyright",
        "clangd"
    	}
    },
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "neovim/nvim-lspconfig",
    },
}
