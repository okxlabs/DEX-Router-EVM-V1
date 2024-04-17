module.exports = {
    skipFiles: ['5/', 'UnxswapV3Router', 'mock/ProxyAdmin'],
    istanbulFolder: "./coverage",
    istanbulReporter: ['html'],
    configureYulOptimizer: true,
};