require 'chef_helper'

describe 'gitlab::mattermost' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(mattermost: { enable: true })
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:database_exists?).and_return(true)
  end

  it 'authorizes mattermost with gitlab' do
    stub_gitlab_rb(external_url: 'http://external.url')
    allow(MattermostHelper).to receive(:authorize_with_gitlab)

    expect(chef_run).to run_ruby_block('authorize mattermost with gitlab')
      .at_converge_time
    expect(MattermostHelper).to receive(:authorize_with_gitlab)
      .with 'http://external.url'

    chef_run.ruby_block('authorize mattermost with gitlab').old_run_action(:run)
  end

  it 'populates mattermost configuration options to node attributes' do
    stub_gitlab_rb(mattermost: { enable: true, gitlab_id: 'old' })
    allow(MattermostHelper).to receive(:authorize_with_gitlab) do |url|
      Gitlab['mattermost']['gitlab_id'] = 'new'
    end

    expect(chef_run).to run_ruby_block('populate mattermost configuration options')
      .at_converge_time

    chef_run.ruby_block('authorize mattermost with gitlab').old_run_action(:run)
    chef_run.ruby_block('populate mattermost configuration options').old_run_action(:run)

    expect(chef_run.node['gitlab']['mattermost']['gitlab_id']).to eq 'new'
  end

  it 'creates mattermost configuration file with gitlab settings' do
    stub_gitlab_rb(mattermost: {
      enable: true,
      gitlab_enable: true,
      gitlab_id: 'gitlab_id',
      gitlab_secret: 'gitlab_secret',
      gitlab_scope: 'scope',
      gitlab_auth_endpoint: 'http://example.com/auth/endpoint',
      gitlab_token_endpoint: 'http://example.com/token/endpoint',
      gitlab_user_api_endpoint: 'http://example.com/user/api/endpoint',
    })

    expect(chef_run).to render_file('/var/opt/gitlab/mattermost/config.json')
      .with_content { |content|
        config = JSON.parse(content)
        expect(config).to have_key 'GitLabSettings'
        expect(config['GitLabSettings']['Enable']).to be true
        expect(config['GitLabSettings']['Secret']).to eq 'gitlab_secret'
        expect(config['GitLabSettings']['Id']).to eq 'gitlab_id'
        expect(config['GitLabSettings']['Scope']).to eq 'scope'
        expect(config['GitLabSettings']['AuthEndpoint']).to eq 'http://example.com/auth/endpoint'
        expect(config['GitLabSettings']['TokenEndpoint']).to eq 'http://example.com/token/endpoint'
        expect(config['GitLabSettings']['UserApiEndpoint']).to eq 'http://example.com/user/api/endpoint'
      }
  end

  it 'creates mattermost configuration file in specified home folder' do
    stub_gitlab_rb(mattermost: {
      enable: true,
      home: '/var/local/gitlab/mattermost',
    })

    expect(chef_run).to render_file('/opt/gitlab/sv/mattermost/run').with_content(/\-config \/var\/local\/gitlab\/mattermost\/config.json/)
  end

  shared_examples 'no gitlab authorization performed' do
    it 'does not authorize mattermost with gitlab' do
      expect(chef_run).to_not run_ruby_block('authorize mattermost with gitlab')
    end
  end

  context 'when gitlab authentication parameters are specified explicitly' do
    before { stub_gitlab_rb(mattermost: { enable: true, gitlab_enable: true }) }

    it_behaves_like 'no gitlab authorization performed'
  end

  context 'when gitlab-rails is disabled' do
    before { stub_gitlab_rb(gitlab_rails: { enable: false }) }

    it_behaves_like 'no gitlab authorization performed'
  end

  context 'when database is not running' do
    before { allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(false) }

    it_behaves_like 'no gitlab authorization performed'
  end

  context 'when mattermost database does not exist' do
    before { allow_any_instance_of(PgHelper).to receive(:database_exists?).and_return(false) }

    it_behaves_like 'no gitlab authorization performed'
  end

end
