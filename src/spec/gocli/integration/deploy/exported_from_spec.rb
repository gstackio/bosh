require 'spec_helper'
require 'fileutils'

describe 'exported_from releases', type: :integration do
  with_reset_sandbox_before_each

  before do
    upload_cloud_config
    bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-centos-7-go_agent.tgz')}")
  end

  let(:jobs) do
    [{ 'name' => 'job_using_pkg_1', 'release' => 'test_release' }]
  end
  let(:manifest) do
    Bosh::Spec::NewDeployments.simple_manifest_with_instance_groups(name: 'ig-name', jobs: jobs).tap do |manifest|
      manifest.merge!(
        'releases' => [{
          'name' => 'test_release',
          'version' => '1',
          'exported_from' => [{ 'os' => 'centos-7', 'version' => '3001.1' }],
        }],
        'stemcells' => [{
          'alias' => 'default',
          'os' => 'centos-7',
          'version' => '3001',
        }],
      )
    end
  end

  let(:targeted_release) { 'compiled_releases/release-test_release-1-on-centos-7-stemcell-3001.1.tgz' }
  let(:decoy_newer_release) { 'compiled_releases/release-test_release-1-on-centos-7-stemcell-3001.2.tgz' }

  context 'when new compiled releases have been uploaded after a deployment' do
    before do
      bosh_runner.run("upload-release #{spec_asset(targeted_release)}")
      deploy(manifest_hash: manifest)

      bosh_runner.run("upload-release #{spec_asset(decoy_newer_release)}")
    end

    it 'a no-op deploy does not update any VMs' do
      output = deploy(manifest_hash: manifest)
      expect(output).not_to include 'Updating instance'
    end
  end
end
