/* Post-render utilities for Mermaid sequence diagram styling.
   Applies per-participant colors by matching substrings in actor labels. */

const PARTICIPANT_COLORS = {
  'UI':     { fill: '#071a0d', stroke: '#22d167', text: '#56d364' },
  'World':  { fill: '#071a0d', stroke: '#22d167', text: '#56d364' },
  'Client': { fill: '#071228', stroke: '#3b9eff', text: '#79c0ff' },
  'Guest':  { fill: '#071228', stroke: '#3b9eff', text: '#79c0ff' },
  'Server': { fill: '#140722', stroke: '#b060ff', text: '#d2a8ff' },
  'Host':   { fill: '#140722', stroke: '#b060ff', text: '#d2a8ff' },
};

function colorSequenceActors() {
  document.querySelectorAll('.mermaid svg').forEach(function(svg) {
    svg.querySelectorAll('text.actor').forEach(function(textEl) {
      const label = textEl.textContent.trim();
      for (const [key, colors] of Object.entries(PARTICIPANT_COLORS)) {
        if (label.includes(key)) {
          const rect = textEl.parentElement.querySelector('rect');
          if (rect) {
            rect.setAttribute('fill', colors.fill);
            rect.setAttribute('stroke', colors.stroke);
          }
          textEl.style.fill = colors.text;
          textEl.querySelectorAll('tspan').forEach(function(t) { t.style.fill = colors.text; });
          break;
        }
      }
    });
  });
}

window.addEventListener('load', function() { setTimeout(colorSequenceActors, 300); });
