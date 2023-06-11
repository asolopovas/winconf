-- Starting with wp_users
DELETE FROM wp_users WHERE ID = 0;
ALTER TABLE wp_users ADD PRIMARY KEY  (ID);
ALTER TABLE wp_users ADD KEY user_login_key (user_login);
ALTER TABLE wp_users ADD KEY user_nicename (user_nicename);
ALTER TABLE wp_users ADD KEY user_email (user_email);
ALTER TABLE wp_users MODIFY ID bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_usermeta
DELETE FROM wp_usermeta WHERE umeta_id = 0;
ALTER TABLE wp_usermeta ADD PRIMARY KEY  (umeta_id);
ALTER TABLE wp_usermeta ADD KEY user_id (user_id);
ALTER TABLE wp_usermeta ADD KEY meta_key (meta_key(191));
ALTER TABLE wp_usermeta MODIFY umeta_id bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_posts
DELETE FROM wp_posts WHERE ID = 0;
ALTER TABLE wp_posts ADD PRIMARY KEY  (ID);
ALTER TABLE wp_posts ADD KEY post_name (post_name(191));
ALTER TABLE wp_posts ADD KEY type_status_date (post_type,post_status,post_date,ID);
ALTER TABLE wp_posts ADD KEY post_parent (post_parent);
ALTER TABLE wp_posts ADD KEY post_author (post_author);
ALTER TABLE wp_posts MODIFY ID bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_comments
DELETE FROM wp_comments WHERE comment_ID = 0;
ALTER TABLE wp_comments ADD PRIMARY KEY  (comment_ID);
ALTER TABLE wp_comments ADD KEY comment_post_ID (comment_post_ID);
ALTER TABLE wp_comments ADD KEY comment_approved_date_gmt (comment_approved,comment_date_gmt);
ALTER TABLE wp_comments ADD KEY comment_date_gmt (comment_date_gmt);
ALTER TABLE wp_comments ADD KEY comment_parent (comment_parent);
ALTER TABLE wp_comments ADD KEY comment_author_email (comment_author_email(10));
ALTER TABLE wp_comments MODIFY comment_ID bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_links
DELETE FROM wp_links WHERE link_id = 0;
ALTER TABLE wp_links ADD PRIMARY KEY  (link_id);
ALTER TABLE wp_links ADD KEY link_visible (link_visible);
ALTER TABLE wp_links MODIFY link_id bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_options
DELETE FROM wp_options WHERE option_id = 0;
ALTER TABLE wp_options ADD PRIMARY KEY  (option_id);
ALTER TABLE wp_options ADD UNIQUE KEY option_name (option_name);
ALTER TABLE wp_options ADD KEY autoload (autoload);
ALTER TABLE wp_options MODIFY option_id bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_postmeta
DELETE FROM wp_postmeta WHERE meta_id = 0;
ALTER TABLE wp_postmeta ADD PRIMARY KEY  (meta_id);
ALTER TABLE wp_postmeta ADD KEY post_id (post_id);
ALTER TABLE wp_postmeta ADD KEY meta_key (meta_key(191));
ALTER TABLE wp_postmeta MODIFY meta_id bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_terms
DELETE FROM wp_terms WHERE term_id = 0;
ALTER TABLE wp_terms ADD PRIMARY KEY  (term_id);
ALTER TABLE wp_terms ADD KEY slug (slug(191));
ALTER TABLE wp_terms ADD KEY name (name(191));
ALTER TABLE wp_terms MODIFY term_id bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_term_taxonomy
DELETE FROM wp_term_taxonomy WHERE term_taxonomy_id = 0;
ALTER TABLE wp_term_taxonomy ADD PRIMARY KEY  (term_taxonomy_id);
ALTER TABLE wp_term_taxonomy ADD UNIQUE KEY term_id_taxonomy (term_id,taxonomy);
ALTER TABLE wp_term_taxonomy ADD KEY taxonomy (taxonomy);
ALTER TABLE wp_term_taxonomy MODIFY term_taxonomy_id bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_term_relationships
DELETE FROM wp_term_relationships WHERE object_id = 0;
DELETE FROM wp_term_relationships WHERE term_taxonomy_id = 0;
ALTER TABLE wp_term_relationships ADD PRIMARY KEY  (object_id,term_taxonomy_id);
ALTER TABLE wp_term_relationships ADD KEY term_taxonomy_id (term_taxonomy_id);
-- Starting with wp_termmeta
DELETE FROM wp_termmeta WHERE meta_id = 0;
ALTER TABLE wp_termmeta ADD PRIMARY KEY  (meta_id);
ALTER TABLE wp_termmeta ADD KEY term_id (term_id);
ALTER TABLE wp_termmeta ADD KEY meta_key (meta_key(191));
ALTER TABLE wp_termmeta MODIFY meta_id bigint(20) unsigned NOT NULL auto_increment;
-- Starting with wp_commentmeta
DELETE FROM wp_commentmeta WHERE meta_id = 0;
ALTER TABLE wp_commentmeta ADD PRIMARY KEY  (meta_id);
ALTER TABLE wp_commentmeta ADD KEY comment_id (comment_id);
ALTER TABLE wp_commentmeta ADD KEY meta_key (meta_key(191));
ALTER TABLE wp_commentmeta MODIFY meta_id bigint(20) unsigned NOT NULL auto_increment;
