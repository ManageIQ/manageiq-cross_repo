require 'tmpdir'
require 'mixlib/archive'

describe ManageIQ::CrossRepo::Repository do
  let(:sha) { "3f8339abf642fafd452a48d20fc6696a17aa49a1" }
  context "#initialize" do
    context "with a branch" do
      let(:branch) { "master" }
      before do
        allow_any_instance_of(described_class).to receive(:git_branch_to_sha)
          .with(anything, branch)
          .and_return(sha)
      end

      context "with just a repository name" do
        it "sets the proper defaults" do
          repo = described_class.new("manageiq")

          expect(repo.org).to  eq("ManageIQ")
          expect(repo.repo).to eq("manageiq")
          expect(repo.sha).to  eq(sha)
          expect(repo.url).to  eq("https://github.com/ManageIQ/manageiq")
        end
      end

      context "with a repository URL" do
        it "uses the correct repository" do
          repo = described_class.new("https://github.com/JoeSmith/manageiq")
          expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("JoeSmith", "manageiq@#{sha}"))
        end
      end

      context "with a different organization" do
        it "sets the correct org" do
          repo = described_class.new("JoeSmith/manageiq")

          expect(repo.org).to eq("JoeSmith")
        end
      end

      context "with a specific branch" do
        let(:branch) { "feature1" }

        it "uses the branch" do
          repo = described_class.new("JoeSmith/manageiq@feature1")

          expect(repo.url).to  eq("https://github.com/JoeSmith/manageiq")
          expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("JoeSmith", "manageiq@#{sha}"))
        end

        it "in a URL format" do
          repo = described_class.new("https://github.com/JoeSmith/manageiq/tree/#{branch}")

          expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("JoeSmith", "manageiq@#{sha}"))
        end

        context "that doesn't exist" do
          let(:sha) { nil }

          it "raises an ArgumentError" do
            expect { described_class.new("manageiq@#{branch}") }
              .to raise_exception(ArgumentError, "manageiq@#{branch} does not exist")
          end
        end
      end
    end

    context "with a specific ref" do
      it "uses the ref" do
        repo = described_class.new("manageiq@#{sha}")

        expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("ManageIQ", "manageiq@#{sha}"))
      end

      it "in a URL format" do
        repo = described_class.new("https://github.com/ManageIQ/manageiq/commit/#{sha}")

        expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("ManageIQ", "manageiq@#{sha}"))
      end
    end

    context "with a PR" do
      let(:pr) { "1" }
      context "merge commit exists" do
        before do
          allow_any_instance_of(described_class).to receive(:git_branch_to_sha)
            .with(anything, "refs/pull/#{pr}/merge")
            .and_return(sha)
        end

        it "expands the PR into a sha" do
          repo = described_class.new("manageiq##{pr}")

          expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("ManageIQ", "manageiq@#{sha}"))
        end

        it "expands a PR URL into a sha" do
          repo = described_class.new("https://github.com/ManageIQ/manageiq/pull/#{pr}")

          expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("ManageIQ", "manageiq@#{sha}"))
        end
      end

      context "merge commit does not exist" do
        before do
          allow_any_instance_of(described_class).to receive(:git_branch_to_sha)
            .with(anything, "refs/pull/#{pr}/merge")
            .and_return(nil)
          allow_any_instance_of(described_class).to receive(:git_branch_to_sha)
            .with(anything, "refs/pull/#{pr}/head")
            .and_return(sha)
        end

        it "expands the PR into a sha" do
          repo = described_class.new("manageiq##{pr}")

          expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("ManageIQ", "manageiq@#{sha}"))
        end

        it "expands a PR URL into a sha" do
          repo = described_class.new("https://github.com/ManageIQ/manageiq/pull/#{pr}")

          expect(repo.path).to eq(ManageIQ::CrossRepo::REPOS_DIR.join("ManageIQ", "manageiq@#{sha}"))
        end
      end
    end
  end

  context "#core?" do
    let(:branch) { "master" }
    before do
      allow_any_instance_of(described_class).to receive(:git_branch_to_sha)
        .with(anything, branch)
        .and_return(sha)
    end

    it "with the core repo" do
      expect(described_class.new("manageiq").core?).to be_truthy
    end

    it "with a plugin repo" do
      expect(described_class.new("manageiq-providers-amazon").core?).to be_falsy
    end
  end

  context "#==" do
    it "with the same identifier is equal" do
      repo1 = described_class.new("manageiq@#{sha}")
      repo2 = described_class.new("manageiq@#{sha}")

      expect(repo1).to eq(repo2)
    end

    it "with different identifiers is not equal" do
      repo1 = described_class.new("manageiq@#{sha}")
      repo2 = described_class.new("manageiq-ui-classic@9ce90e18be2fc2d0fd864d89c09790bd9d4b45bb")

      expect(repo1).not_to eq(repo2)
    end

    it "the same repo and sha in different orgs is equal" do
      repo1 = described_class.new("manageiq@#{sha}")
      repo2 = described_class.new("JohnDoe/manageiq@#{sha}")

      expect(repo1).to eq(repo2)
    end
  end

  context "#ensure_clone" do
    subject { described_class.new("ManageIQ/manageiq-cross_repo") }

    let!(:extract_dir)       { Pathname.new Dir.mktmpdir }
    let!(:temp_dir)          { Pathname.new Dir.mktmpdir }

    let!(:extract_file_path) { extract_dir.join("README.md") }
    let!(:fake_tarball)      { temp_dir.join("not_a_tarball") }
    let!(:fake_uri)          { "file://#{fake_tarball.to_s}" }
    let!(:tarball_path)      { temp_dir.join("tarball.tar.gz") }
    let!(:tarball_file_path) { temp_dir.join("README.md").to_s }
    let!(:tarball_file)      { File.write(tarball_file_path, "# MY README") } 

    before do
      Mixlib::Archive.new(tarball_path.to_s).create([tarball_file_path], gzip: true)

      allow(Dir).to     receive(:mktmpdir).and_yield(extract_dir.to_s)
      allow(subject).to receive(:puts).and_return(nil)
      allow(subject).to receive(:sleep).and_return(nil) # for speed
      allow(subject).to receive(:tarball_url).and_return(*tarball_url_returns)
      allow(subject).to receive(:path).and_return(extract_file_path)
    end

    context "with a working tarball" do
      let(:tarball_url_returns) { [tarball_path] }

      it "extracts the tar.gz" do
        subject.ensure_clone

        expect(File).to exist(extract_file_path)
      end
    end

    context "with a failed first two attempts" do
      let(:tarball_url_returns) do
        [fake_uri, fake_uri, fake_uri, fake_uri, tarball_path, tarball_path]
      end

      it "extracts the tar.gz" do
        subject.ensure_clone

        expect(File).to exist(extract_file_path)
      end
    end

    context "with more than three failed  attempts" do
      let(:tarball_url_returns) { [fake_uri] }

      it "extracts the tar.gz" do
        expect { subject.ensure_clone }.to raise_error Errno::ENOENT
      end
    end
  end
end
