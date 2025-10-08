function(response) {
  var type = karate.typeOf(response);
  if (type === 'map') {
    var message = response.errorMessage;
    if (!message) {
      throw 'Respuesta inesperada sin errorMessage: ' + JSON.stringify(response);
    }
    return message;
  }
  if (type === 'string') {
    var trimmed = response.trim();
    if (trimmed === '""') {
      throw 'Se esperaba un mensaje de error pero se recibió cadena vacía';
    }
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      var parsed = JSON.parse(trimmed);
      if (!parsed.errorMessage) {
        throw 'Respuesta JSON sin errorMessage: ' + trimmed;
      }
      return parsed.errorMessage;
    }
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      trimmed = trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }
  throw 'Tipo de respuesta no soportado: ' + type;
}
