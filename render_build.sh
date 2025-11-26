#!/usr/bin/env bash
# Indica ao Render para parar se um comando falhar
set -e

echo "==> Instalando o Flutter SDK 3.24.3 (Stable)..."

wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
tar xf flutter_linux_3.24.3-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

echo "==> Flutter SDK instalado."

echo "==> Gerando arquivo .env (Segredos)..."

# Escreve o arquivo no caminho 'assets/env' que o main.dart espera
echo "BACKEND_URL=$BACKEND_URL" > assets/env
echo "SUPABASE_URL=$SUPABASE_URL" >> assets/env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> assets/env
echo "SUPABASE_URL_CALLBACK=$SUPABASE_URL_CALLBACK" >> assets/env
echo "SUPABASE_REDIRECT_URI=$SUPABASE_REDIRECT_URI" >> assets/env
# --- FIM DA CORREÇÃO ---

echo "==> Habilitando a Web..."
flutter config --enable-web

echo "==> Instalando dependências..."
flutter pub get

echo "==> Compilando o App (Build)..."
flutter build web --web-renderer canvaskit --release
#flutter build web --web-renderer html --release

echo "==> Build completo."