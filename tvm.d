module tvm;

import tagion.utils.JSONCommon;

/++
 Options for the network
+/
struct Options {
    int x;
    mixin JSONCommon;
    mixin JSONConfig;
}

int main(string[] args) {
//    auto net_opts = getopt(args, std.getopt.config.passThrough, "net-mode", &(local_options.net_mode));

    return 0;
}
