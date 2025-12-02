#!/usr/bin/env bash
# Indica ao Render para parar se um comando falhar
set -e

# --- MUDANÇA 1: Instalação Dinâmica (Sempre a mais atual) ---
echo "==> Verificando Flutter SDK..."

# Define o canal estável
FLUTTER_CHANNEL="stable"

# Se a pasta já existe (cache do Render), apenas atualiza
if [ -d "flutter" ]; then
    echo "==> Atualizando Flutter existente..."
    cd flutter
    git pull
    bin/flutter channel $FLUTTER_CHANNEL
    bin/flutter upgrade
    cd ..
else
    # Se não existe, baixa do zero
    echo "==> Baixando Flutter Stable..."
    git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL
fi

# Adiciona ao Path
export PATH="$PATH:`pwd`/flutter/bin"

echo "==> Versão instalada:"
flutter --version
# -----------------------------------------------------------

echo "==> Gerando arquivo .env (Segredos)..."

# (Sua lógica original mantida)
echo "BACKEND_URL=$BACKEND_URL" > assets/env
echo "SUPABASE_URL=$SUPABASE_URL" >> assets/env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> assets/env
echo "SUPABASE_URL_CALLBACK=$SUPABASE_URL_CALLBACK" >> assets/env
echo "SUPABASE_REDIRECT_URI=$SUPABASE_REDIRECT_URI" >> assets/env

echo "==> Habilitando a Web..."
flutter config --enable-web

echo "==> Limpando e Instalando dependências..."
flutter clean
flutter pub get

echo "==> Compilando o App (Build)..."
# Adicionei --no-tree-shake-icons para evitar um bug comum de ícones sumindo na web
flutter build web --release --no-tree-shake-icons

echo "==> Build completo!"
