# Composer
function ci { composer install }
function cr { composer require $args }

# pnpm
function pi { pnpm install $args }
function pu { pnpm update $args}

# Poetry
function pr { poetry run $args }