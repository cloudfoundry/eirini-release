# What is this?

Bosh release for the github.com/julz/cube project

# How do I get started

Checkout the source and run the following:

bosh sync-blobs
bosh create-release
bosh upload-release
bosh -d cube deploy
