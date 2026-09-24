#import "Basic";
#import "File";
#import "Compiler";

#run {
    set_build_options_dc(.{do_output = false});

    workspace := compiler_create_workspace("Target Program");
    if !workspace {
        print("Failed to create workspace.\n");
        return;
    }

    // customize output
    build_options := get_build_options(workspace);
    copy_commonly_propagated_fields(get_build_options(), *build_options);
    build_options.output_executable_name = "sample";
    make_directory_if_it_does_not_exist("./bin");
    build_options.output_path = "./bin";
    build_options.output_type = .EXECUTABLE;
    set_build_options(build_options, workspace);

    // source files
    add_build_file("./sample/main.jai", workspace);
}