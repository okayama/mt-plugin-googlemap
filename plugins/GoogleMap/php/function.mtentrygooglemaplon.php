<?php
function smarty_function_mtentrygooglemaplon ( $args, &$ctx ) {
    $entry = $ctx->stash( 'entry' );
    if ( $entry[ 'entry_lon' ] ) {
        return $entry[ 'entry_lon' ];
    }
    return '';
}
?>
