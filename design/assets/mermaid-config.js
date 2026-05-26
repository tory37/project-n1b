/* Shared Mermaid configuration for all design diagrams */
mermaid.initialize({
  startOnLoad: true,
  theme: 'base',
  themeVariables: {
    background: '#090d12',
    primaryColor: '#1a2233',
    primaryTextColor: '#e6edf3',
    primaryBorderColor: '#30363d',
    lineColor: '#58a6ff',
    secondaryColor: '#161b22',
    tertiaryColor: '#21262d',
    fontSize: '14px',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif',

    // Sequence — participant boxes (JS post-colors individual actors)
    actorBkg: '#161b22',
    actorBorder: '#30363d',
    actorTextColor: '#e6edf3',
    actorLineColor: '#30363d',

    // Sequence — arrows & labels
    signalColor: '#79c0ff',
    signalTextColor: '#c9d1d9',
    labelBoxBkgColor: '#161b22',
    labelBoxBorderColor: '#30363d',
    labelTextColor: '#8b949e',
    loopTextColor: '#e6edf3',

    // Sequence — notes & activations
    noteBkgColor: '#1c2434',
    noteTextColor: '#c9d1d9',
    noteBorderColor: '#30363d',
    activationBorderColor: '#58a6ff',
    activationBkgColor: '#1a2a3a',

    // Flowchart
    edgeLabelBackground: '#161b22',
    clusterBkg: '#161b22',
    titleColor: '#e6edf3',
  }
});
