<?php
function smarty_function_mtentrygooglemaplat ( $args, &$ctx ) {
    $entry = $ctx->stash( 'entry' );
    if ( $entry[ 'entry_lat' ] ) {
        return $entry[ 'entry_lat' ];
    }
    return '';
}
?>
