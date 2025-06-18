// enhancedCheckUsage.js
const fs = require('fs');
const path = require('path');

const targetFileName = 'diamond-helpers.js'; // Change as needed
const projectRoot = process.cwd();

const fileDependencies = new Map(); // file -> [files it references]

function readFileIfExists(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch {
    return null;
  }
}

function resolveImportPath(importPath, baseDir) {
  if (importPath.startsWith('.')) {
    // relative import
    const extensions = ['.js', '.ts', '.jsx', '.tsx', '/index.js', '/index.ts'];
    for (const ext of extensions) {
      const fullPath = path.resolve(baseDir, importPath + ext);
      if (fs.existsSync(fullPath)) return fullPath;
    }
    // fallback, try raw
    return path.resolve(baseDir, importPath);
  }
  // For node_modules or absolute imports, skip
  return null;
}

function extractImports(fileContent) {
  const importRegex = /import\s+(?:[^'"]+from\s+)?['"](.+?)['"]/g;
  const requireRegex = /require\(['"](.+?)['"]\)/g;

  const imports = [];
  let match;

  while ((match = importRegex.exec(fileContent)) !== null) {
    imports.push(match[1]);
  }
  while ((match = requireRegex.exec(fileContent)) !== null) {
    imports.push(match[1]);
  }

  return imports;
}

function scanDirectory(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      scanDirectory(fullPath);
    } else if (entry.isFile()) {
      const ext = path.extname(entry.name);
      if (['.js', '.ts', '.jsx', '.tsx'].includes(ext)) {
        const content = readFileIfExists(fullPath);
        if (!content) continue;

        const imports = extractImports(content);
        const resolvedDeps = [];

        for (const imp of imports) {
          const resolved = resolveImportPath(imp, path.dirname(fullPath));
          if (resolved) {
            resolvedDeps.push(resolved);
          }
        }

        fileDependencies.set(fullPath, resolvedDeps);
      }
    }
  }
}

function findFilesReferencingTarget() {
  const referencingFiles = [];

  for (const [file, deps] of fileDependencies.entries()) {
    for (const dep of deps) {
      if (dep.endsWith(targetFileName)) {
        referencingFiles.push(file);
        break;
      }
    }
  }

  return referencingFiles;
}

function findIndirectReferences(filesWithDirectRef) {
  // We'll find all files that depend (directly or indirectly) on targetFile

  const indirectlyReferencing = new Set(filesWithDirectRef);

  // Because dependencies go from file->deps, we need reverse map for traversing "who depends on whom"
  const reverseDeps = new Map(); // depFile -> [files depending on depFile]

  for (const [file, deps] of fileDependencies.entries()) {
    for (const dep of deps) {
      if (!reverseDeps.has(dep)) reverseDeps.set(dep, []);
      reverseDeps.get(dep).push(file);
    }
  }

  // BFS starting from direct references
  const queue = [...filesWithDirectRef];
  while (queue.length) {
    const current = queue.shift();
    const parents = reverseDeps.get(current) || [];
    for (const parent of parents) {
      if (!indirectlyReferencing.has(parent)) {
        indirectlyReferencing.add(parent);
        queue.push(parent);
      }
    }
  }

  return [...indirectlyReferencing];
}

function main() {
  console.log(`Scanning directory: ${projectRoot} for references to ${targetFileName}...\n`);
  scanDirectory(projectRoot);

  const directRefs = findFilesReferencingTarget();
  if (directRefs.length === 0) {
    console.log(`No direct references found to ${targetFileName}.`);
  } else {
    console.log(`Direct references to ${targetFileName} found in:`);
    for (const file of directRefs) {
      console.log(`  - ${file}`);
    }
  }

  const allRefs = findIndirectReferences(directRefs);
  if (allRefs.length === 0) {
    console.log(`\nNo indirect references found.`);
  } else {
    console.log(`\nIndirect and direct references (dependency chain) including:`);
    for (const file of allRefs) {
      console.log(`  - ${file}`);
    }
  }

  // Summary about safe removal
  const allFiles = Array.from(fileDependencies.keys());
  const safeToRemove = allFiles.filter(f => !allRefs.includes(f) && !f.endsWith(targetFileName));

  console.log(`\n\nSummary:`);
  console.log(`Total scanned files: ${allFiles.length}`);
  console.log(`Files referencing (directly or indirectly) ${targetFileName}: ${allRefs.length}`);
  console.log(`Files safe to remove without affecting ${targetFileName}: ${safeToRemove.length}`);

  if (safeToRemove.length > 0) {
    console.log(`\nFiles NOT depending on ${targetFileName} (candidates to clean):`);
    for (const f of safeToRemove) {
      console.log(`  - ${f}`);
    }
  }

  console.log('\nScan complete.');
}

main();
