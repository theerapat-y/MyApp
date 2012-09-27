#!/usr/bin/env perl
 
use strict;
use warnings;
use Test::More;
 
# Need to specify the name of your app as arg on next line
# Can also do:
#   use Test::WWW::Mechanize::Catalyst "MyApp";
 
BEGIN { use_ok("Test::WWW::Mechanize::Catalyst" => "MyApp") }
 
# Create two 'user agents' to simulate two different users ('test01' & 'test02')
my $ua1 = Test::WWW::Mechanize::Catalyst->new;
my $ua2 = Test::WWW::Mechanize::Catalyst->new;
 
# Use a simplified for loop to do tests that are common to both users
# Use get_ok() to make sure we can hit the base URL
# Second arg = optional description of test (will be displayed for failed tests)
# Note that in test scripts you send everything to 'http://localhost'
$_->get_ok("http://localhost/", "Check redirect of base URL") for $ua1, $ua2;
# Use title_is() to check the contents of the <title>...</title> tags
$_->title_is("Login", "Check for login title") for $ua1, $ua2;
# Use content_contains() to match on text in the html body
$_->content_contains("You need to log in to use this application",
    "Check we are NOT logged in") for $ua1, $ua2;

# Log in as each user
$ua1->post_ok("http://localhost/login", {username => 'test01', password => 'mypass'},'Login as test01');
$ua2->get_ok("http://localhost/login", "Go to login page 'test02'");
# Try submit empty form login
$ua2->submit_form(
    fields => {
        username => '',
        password => '',
    });
# Warning msg should display
$ua2->content_contains("Please enter username and password", "Check empty form cannot login");
# Could make user2 like user1 above, but use the form to show another way
$ua2->submit_form(
    fields => {
        username => 'test02',
        password => 'mypass',
    });
 
# Go back to the login page and it should show that we are already logged in
$_->get_ok("http://localhost/login", "Return to '/login'") for $ua1, $ua2;
$_->title_is("Login", "Check for login page") for $ua1, $ua2;
$_->content_contains("Please Note: You are already logged in as ",
    "Check we ARE logged in" ) for $ua1, $ua2;
 
# 'Click' the 'Logout' link (see also 'text_regex' and 'url_regex' options)
$_->get_ok("http://localhost/logout", "Logout from page") for $ua1, $ua2;
$_->title_is("Login", "Check for login title") for $ua1, $ua2;
$_->content_contains("You need to log in to use this application",
    "Check we are NOT logged in") for $ua1, $ua2;
 
# Log back in
$ua1->post_ok("http://localhost/login", {username => 'test01', password => 'mypass'},'Login as test01');
$ua2->post_ok("http://localhost/login", {username => 'test02', password => 'mypass'},'Login as test02');
# Should be at the Book List page... do some checks to confirm
$_->title_is("Book List", "Check for book list title") for $ua1, $ua2;
 
$ua1->get_ok("http://localhost/books/list", "'test01' book list");
$ua1->get_ok("http://localhost/login", "Login Page");
$ua1->get_ok("http://localhost/books/list", "'test01' book list");
 
$_->content_contains("Book List", "Check for book list title") for $ua1, $ua2;
# Make sure the appropriate logout buttons are displayed
$_->content_contains("/logout\">Logout</a>",
    "Both users should have a 'User Logout'") for $ua1, $ua2;
$ua1->content_contains("/books/formfu_create\">Create Book</a>",
    "'test01' should have a create link");
$ua2->content_lacks("/books/formfu_create\">Create Book</a>",
    "'test02' should NOT have a create link");
 
$ua1->get_ok("http://localhost/books/list", "View book list as 'test01'");
 
# User 'test01' should be able to create a book with the "formfu create"
$ua1->get_ok("http://localhost/books/formfu_create", "'test01' formfu create page");
$ua1->submit_form(
    fields => {
        title => 'TestTitle',
        rating => '5',
        authors => '1'
        },
        button => 'submit'
    );

# Check for response if book has been created
$ua1->content_contains("Book created", "Book created notification");

# Make sure the new book shows in the list
$ua1->get_ok("http://localhost/books/list", "'test01' book list");
$ua1->title_is("Book List", "Check logged in and at book list");
$ua1->content_contains("Book List", "Book List page test");
$ua1->content_contains("TestTitle", "Check book added OK");

# Check the new book can be edit
# Get all the Edit links on the list page
my @editLinks = $ua1->find_all_links(text => 'Edit');
# Use the final link to edit the last book
$ua1->get_ok($editLinks[$#editLinks]->url, 'Edit last book');
# Check title in edit page
$ua1->title_is("Update Book", "Check user 'test01' in 'Update book'");
# Edit the book
$ua1->submit_form(
    fields => {
        title => 'TestTitleEdit',
        rating => '5',
        authors => '1'
        },
        button => 'submit'
    );
# Check that edit worked
$ua1->content_contains("Book List", "Book List page test");
$ua1->content_like(qr/edited successfully/, "edited book #");
 
# Make sure the new book can be deleted
# Get all the Delete links on the list page
my @delLinks = $ua1->find_all_links(text => 'Delete');
# Use the final link to delete the last book
$ua1->get_ok($delLinks[$#delLinks]->url, 'Delete last book');
# Check that delete worked
$ua1->content_contains("Book List", "Book List page test");
$ua1->content_like(qr/TestTitleEdit is deleted./, "deleted book #");

# Check that user 'test 01' cannot update book that non exist
$ua1->get_ok("http://localhost/books/id/0/formfu_edit", "'test01' try edit non-exist book");
$ua1->content_like(qr/Invalid book/, "'Book 0 isn't exist");

# Check that user 'test 01' cannot delete book that non exist
$ua1->get_ok("http://localhost/books/id/0/delete", "'test01' try delete non-exist book");
$ua1->content_like(qr/Invalid book/, "'Book 0 isn't exist");

# User 'test02' should not be able to add a book
$ua2->get_ok("http://localhost/books/formfu_create", "'test02' try access formfu create");
$ua2->content_contains("not authorized", "Check 'test02' cannot access");

# Check that user 'test 01' cannot delete book that non exist
$ua2->get_ok("http://localhost/books/id/15/delete", "'test02' try delete book");
$ua2->content_contains("not authorized", "'Check 'test02' cannot perform delete");
 
done_testing();
