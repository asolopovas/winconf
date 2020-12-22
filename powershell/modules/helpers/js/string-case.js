let args = process.argv.slice(2);
let stringCase = args[0];
let string = args[1];

function camelCase(text) {
    text = text.replace(/[-_\s.]+(.)?/g, (match, c) => c ? c.toUpperCase() : '');
    return text.substr(0, 1).toLowerCase() + text.substr(1);
}

function snakeCase(string) {
  return string.match(/[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g)
               .map(x => x.toLowerCase())
               .join('_');
}

global.camelCase = camelCase
global.snakeCase = snakeCase


console.log(global[stringCase](string))

