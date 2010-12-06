<?php
function smarty_function_mtcategorygooglemaplat ( $args, &$ctx ) {
    $category = $ctx->stash( 'category' );
    $category_lat = $category[ 'category_lat' ];
    if ( $category_lat ) {
        return $category_lat;
    }
    return '';
}
?>
