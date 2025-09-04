namespace :app do
  desc "Rename the application"
  task :rename, [ :old_name, :new_name ] => :environment do |t, args|
    old_name = args[:old_name]
    new_name = args[:new_name]

    if old_name.nil? || new_name.nil?
      puts "Usage: rake app:rename[old_name,new_name]"
      exit(1)
    end

    puts "Renaming application from '#{old_name}' to '#{new_name}'..."

    # Files to process
    files_to_process = [
      "config/application.rb",
      "config/database.yml",
      "config/cable.yml",
      "config/puma.rb",
      "config.ru",
      "Rakefile",
      "README.md",
      # Add other files if necessary, e.g., initializers
      "config/initializers/devise.rb",
      "config/initializers/content_security_policy.rb"
    ]

    # Handle different cases of the name
    replacements = {
      old_name => new_name,
      old_name.underscore => new_name.underscore,
      old_name.camelize(:lower) => new_name.camelize(:lower),
      old_name.upcase => new_name.upcase,
      old_name.downcase => new_name.downcase
    }

    files_to_process.each do |file_path|
      if File.exist?(file_path)
        puts "Processing #{file_path}..."
        content = File.read(file_path)
        new_content = content.dup

        replacements.each do |old_str, new_str|
          new_content.gsub!(old_str, new_str)
        end

        File.write(file_path, new_content)
      else
        puts "Warning: File not found - #{file_path}"
      end
    end

    puts "Application renaming complete. You may need to manually check and update other files."
    puts "Remember to also update the database name in config/database.yml if needed."
    puts "Consider running 'bundle install' and 'rails db:migrate' after renaming."
  end
end
