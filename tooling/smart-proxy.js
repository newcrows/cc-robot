const fs = require('fs');
const path = require('path');

/**
 * Erstellt einen rekursiven Proxy mit Hoisting, Pfad-Ende-Prüfung
 * und schreibweisen-basiertem Export-Zugriff.
 */
function createSmartProxy(rootPath = null) {
  const fileRegistry = [];

  // Verzeichnis rekursiv scannen und JS-Dateien indizieren
  const scan = (dir) => {
    if (!dir || !fs.existsSync(dir)) return;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        scan(fullPath);
      } else if (entry.name.endsWith('.js')) {
        fileRegistry.push(fullPath);
      }
    }
  };

  if (rootPath) scan(rootPath);

  const makeProxy = (currentPathParts = [], loadedModule = null) => {
    // Die Target-Funktion erlaubt den Aufruf: const sub = proxy("/path")
    const target = (newRoot) => createSmartProxy(newRoot);

    return new Proxy(target, {
      get(target, prop) {
        // 1. Wenn Modul geladen: Schreibweisen-Logik (api, def, util)
        if (loadedModule !== null) {
          // PascalCase -> .def (Mapping: PascalCase -> pascalCase)
          if (/^[A-Z]/.test(prop)) {
            const key = prop.charAt(0).toLowerCase() + prop.slice(1);
            return loadedModule.def ? loadedModule.def[key] : undefined;
          }
          // camelCase -> .api
          if (/^[a-z]/.test(prop)) {
            return loadedModule.api ? loadedModule.api[prop] : undefined;
          }
          // _underscore -> .util (Entfernt den Unterstrich)
          if (prop.startsWith('_')) {
            const key = prop.slice(1);
            return loadedModule.util ? loadedModule.util[key] : undefined;
          }
          return loadedModule[prop];
        }

        // Falls der Prop bereits auf dem Target existiert (z.B. durch Zuweisung)
        if (prop in target) return target[prop];

        // 2. Pfad-Auflösung (Hoisting)
        const newPathParts = [...currentPathParts, prop];
        const searchString = path.join(...newPathParts).toLowerCase();

        const matches = fileRegistry.filter(filePath => {
          const rel = path.relative(rootPath, filePath).toLowerCase();
          // Prüft: "path/file.js" ODER ".../path/file.js" ODER "path/file/index.js"
          return rel === `${searchString}.js` ||
            rel.endsWith(`${path.sep}${searchString}.js`) ||
            rel === path.join(searchString, 'index.js') ||
            rel.endsWith(`${path.sep}${path.join(searchString, 'index.js')}`);
        });

        // Kollisionsprüfung
        if (matches.length > 1) {
          throw new Error(`[Proxy Error] Kollision für "${searchString}" in ${rootPath}:\n${matches.join('\n')}`);
        }

        // Datei gefunden -> Modul laden
        if (matches.length === 1) {
          return makeProxy(newPathParts, require(matches[0]));
        }

        // Weitermachen (Chaining)
        return makeProxy(newPathParts);
      },

      // Erlaubt das "Mounten": proxy.a.b = proxy("/path")
      set(target, prop, value) {
        target[prop] = value;
        return true;
      }
    });
  };

  return makeProxy();
}

// Exportiere eine leere Instanz als Startpunkt
module.exports = createSmartProxy();
