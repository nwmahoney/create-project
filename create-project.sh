#!/usr/bin/env bash

set -exu -o pipefail

project_name="${1:?Missing required first argument (project-name). Usage: create-project <project-name>}"
starting_directory="$(pwd)"
tmp_directory="/tmp/${project_name}"
script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

mkdir "${tmp_directory}"
cd "${tmp_directory}"

# install latest LTS version of node
latest_lts_node_major_version="$(asdf nodejs resolve lts)"
latest_lts_node_version="$(ASDF_NODEJS_LEGACY_FILE_DYNAMIC_STRATEGY=latest_available asdf nodejs resolve lts)"
asdf install nodejs "${latest_lts_node_version}"
asdf local nodejs "${latest_lts_node_version}"

# use pnpm that comes with node
corepack enable
asdf reshim

pnpx create-next-app@latest \
  "${project_name}" \
  --typescript \
  --eslint \
  --app \
  --use-pnpm

mv .tool-versions "${project_name}"

cd "${starting_directory}"
mv "${tmp_directory}/${project_name}" .
rm -rf "${tmp_directory}"
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

cat <<EOF >.npmrc
strict-peer-dependencies=true
engine-strict=true
EOF

mkdir -p .github/workflows
cp "$script_directory/gha_cicd_workflow.yml" .github/workflows/cicd.yml

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


MANUAL STEP!!!

Specify NodeJS version in your package.json:

{
  "engines": {
    "node": "${latest_lts_node_major_version}.x"
  }
}


MANUAL STEP!!!

Test that Vitest is set up correctly: https://nextjs.org/docs/app/building-your-application/testing/vitest#creating-your-first-vitest-unit-test


MANUAL STEP!!!

Create a new GitHub repo.


MANUAL STEP!!!

1. Retrieve your [Vercel Access Token](https://vercel.com/guides/how-do-i-use-a-vercel-api-access-token)
2. Install the [Vercel CLI](https://vercel.com/cli) and run \`vercel login\`
3. Inside your folder, run \`vercel link\` to create a new Vercel project
4. Inside the generated \`.vercel\` folder, save the \`projectId\` and \`orgId\` from the \`project.json\`
5. Inside GitHub, add \`VERCEL_TOKEN\`, \`VERCEL_ORG_ID\`, and \`VERCEL_PROJECT_ID\` as [secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)


MANUAL STEP!!!

Commit changes and push to GitHub.

EOF
