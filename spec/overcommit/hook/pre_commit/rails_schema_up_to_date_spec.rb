require 'spec_helper'

describe Overcommit::Hook::PreCommit::RailsSchemaUpToDate do
  let(:config)            { Overcommit::ConfigurationLoader.default_configuration }
  let(:context)           { double('context') }
  let(:ruby_schema_file)  { 'db/schema.rb' }
  let(:sql_schema_file)   { 'db/structure.sql' }

  let(:migration_files) do
    %w[
      db/migrate/20140304042233_some_migration.rb
      db/migrate/20140305123456_some_migration.rb
    ]
  end

  subject { described_class.new(config, context) }

  context "when a migration was added but the schema wasn't updated" do
    before do
      subject.stub(:applicable_files).and_return(migration_files)
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('db/migrate')

        migration_files.each do |migration_file|
          File.open(migration_file, 'w') { |f| f.write('migration') }
          `git add #{migration_file}`
        end

        example.run
      end
    end

    it { should fail_hook }
  end

  context 'when a Ruby schema file was added but no migration files were' do
    before do
      subject.stub(:applicable_files).and_return([ruby_schema_file])
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('db/migrate')
        File.open(ruby_schema_file, 'w') { |f| f.write('version: 20160904205635') }
        `git add #{ruby_schema_file}`
        example.run
      end
    end

    it { should fail_hook }
  end

  context 'when a SQL schema file was added but no migration files were' do
    before do
      subject.stub(:applicable_files).and_return([sql_schema_file])
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('db/migrate')
        File.open(sql_schema_file, 'w') { |f| f.write("VALUES ('20151214213046')") }
        `git add #{sql_schema_file}`
        example.run
      end
    end

    it { should fail_hook }
  end

  context 'when a Ruby schema file with the latest version and migrations are added' do
    before do
      subject.stub(:applicable_files).and_return(migration_files << ruby_schema_file)
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('db/migrate')

        File.open(ruby_schema_file, 'w') { |f| f.write('20140305123456') }
        `git add #{ruby_schema_file}`

        migration_files.each do |migration_file|
          File.open(migration_file, 'w') { |f| f.write('migration') }
          `git add #{migration_file}`
        end

        example.run
      end
    end

    it { should pass }
  end

  context 'when a Ruby schema file which is not at the latest version and migrations are added' do
    before do
      subject.stub(:applicable_files).and_return(migration_files << ruby_schema_file)
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('db/migrate')

        File.open(ruby_schema_file, 'w') { |f| f.write('20140205123456') }
        `git add #{ruby_schema_file}`

        migration_files.each do |migration_file|
          File.open(migration_file, 'w') { |f| f.write('migration') }
          `git add #{migration_file}`
        end

        example.run
      end
    end

    it { should fail_hook }
  end

  context 'when a SQL schema file with the latest version and migrations are added' do
    before do
      subject.stub(:applicable_files).and_return(migration_files << sql_schema_file)
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('db/migrate')

        File.open(sql_schema_file, 'w') { |f| f.write('20140305123456') }
        `git add #{sql_schema_file}`

        migration_files.each do |migration_file|
          File.open(migration_file, 'w') { |f| f.write('migration') }
          `git add #{migration_file}`
        end

        example.run
      end
    end

    it { should pass }
  end

  context 'when schema file w/ latest version and migrations are added in dir w/ number' do
    let(:user_dir) { 'hdd418/' }
    before do
      files = (migration_files << sql_schema_file).map do |file|
        "#{user_dir}#{file}"
      end
      subject.stub(:applicable_files).and_return(files)
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('hdd418/db/migrate')

        File.open(user_dir + sql_schema_file, 'w') { |f| f.write('20140305123456') }
        `git add #{user_dir}#{sql_schema_file}`

        migration_files.each do |migration_file|
          File.open(user_dir + migration_file, 'w') { |f| f.write('migration') }
          `git add #{user_dir}#{migration_file}`
        end

        example.run
      end
    end

    it { should pass }
  end

  context 'when a SQL schema file which is not at the latest version and migrations are added' do
    before do
      subject.stub(:applicable_files).and_return(migration_files << sql_schema_file)
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('db/migrate')

        File.open(sql_schema_file, 'w') { |f| f.write('20140205123456') }
        `git add #{sql_schema_file}`

        migration_files.each do |migration_file|
          File.open(migration_file, 'w') { |f| f.write('migration') }
          `git add #{migration_file}`
        end

        example.run
      end
    end

    it { should fail_hook }
  end

  context 'when the schema file is at version 0 and there are no migrations' do
    before do
      subject.stub(:applicable_files).and_return([ruby_schema_file])
    end

    around do |example|
      repo do
        FileUtils.mkdir_p('db')

        File.open(ruby_schema_file, 'w') { |f| f.write('version: 0') }
        `git add #{ruby_schema_file}`

        example.run
      end
    end

    it { should pass }
  end
end
