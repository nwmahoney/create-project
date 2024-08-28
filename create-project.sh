#!/usr/bin/env bash

set -exu -o pipefail

project_name="${1:?Missing required first argument (project-name). Usage: create-project <project-name>}"
starting_directory="$(pwd)"
tmp_directory="/tmp/${project_name}"

mkdir "${tmp_directory}"
cd "${tmp_directory}"

# install latest version of node
latest_node_version="$(asdf latest nodejs)"
asdf local nodejs "${latest_node_version}"
asdf install nodejs "${latest_node_version}"

# use pnpm that comes with node
corepack enable
asdf reshim

pnpx create-next-app@latest \
  "${project_name}" \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --use-pnpm

mv .tool-versions "${project_name}"

cd "${starting_directory}"
mv "${tmp_directory}/${project_name}" .
cd "${project_name}"

pnpm install -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/dom

cat <<EOF >vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
 
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
  },
})
EOF

git add --all
git commit -m 'Initial commit from create-project.sh'

cat <<EOF

MANUAL STEP!!!

Add a test script to your package.json:

{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "test": "vitest"
  }
}
EOF