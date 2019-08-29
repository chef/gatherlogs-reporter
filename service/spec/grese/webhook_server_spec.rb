RSpec.describe Grese::WebhookServer do
  let(:server) do
    Grese::WebhookServer.new({
      url: 'https://sandbox.zendesk.com'
    }, true)
  end

  it 'should set debug to true' do
    expect(server.debug?).to be true
  end

  it 'debug should default to false' do
    server = Grese::WebhookServer.new(url: 'https://sandbox.zendesk.com')
    expect(server.debug?).to be false
  end

  it 'should validate chef zendesk url' do
    result = server.valid_zendesk_request('https://getchef.zendesk.com')
    expect(result).to be true
  end

  it 'should not validate other urls' do
    result = server.valid_zendesk_request('https://google.com')
    expect(result).to_not be true
  end

  it 'should return an error for invalid url' do
    result = server.check_logs('https://google.com')
    expect(result[:error]).to eq 'Invalid URL'
  end

  it 'should validate gatherlog bundle' do
    result = server.valid_gatherlog_bundle('https://getchef.zendesk.com?name=foo.tar.gz')
    expect(result).to be true
  end

  it 'should validate as a gatherlog bundle' do
    result = server.valid_gatherlog_bundle('https://getchef.zendesk.com?name=foo.txt')
    expect(result).to_not be true
  end

  it 'should return an error for invalid url' do
    result = server.check_logs('https://google.com')
    expect(result[:error]).to eq 'Invalid URL'
  end

  it 'should return an error for invalid gather-log bundle' do
    result = server.check_logs('https://getchef.zendesk.com?name=foo.txt')
    expect(result[:error]).to eq 'Invalid gather-log bundle'
  end

  it 'should execute check_logs' do
    cmd = [
      'gatherlog', 'report', '-m', '--remote',
      'https://getchef.zendesk.com?name=foo.tar.gz'
    ]

    expect(server).to receive(:shellout).with(cmd) {
      double('shellout', stdout: 'Wahoo', stderr: '', exitstatus: 0)
    }

    expect(server.check_logs('https://getchef.zendesk.com?name=foo.tar.gz')).to eq(
      results: 'Wahoo',
      error: '',
      status: 0
    )
  end

  it 'should give a message about no issues' do
    expect(server.zendesk_comment_text('foo.tar.gz', '')).to match(
      /No issues were found in the gather-log bundle/
    )
  end

  it 'should show the checklog output' do
    expect(server.zendesk_comment_text('foo.tar.gz', 'Bag box suddenly here now gone')).to match(
      /Bag box suddenly here now gone/
    )
  end

  it 'should call out to mixlib shellout!' do
    dbl = double('cmd')
    allow(Mixlib::ShellOut).to receive(:new).with('test', {}) { dbl }
    allow(dbl).to receive(:run_command)
    allow(dbl).to receive(:error!)

    expect(server.shellout('test')).to eq dbl
  end

  it 'should return nil if the status is not 0' do
    expect(server.update_zendesk(123, 'test.tar.gz', status: 1)).to be nil
  end

  it 'should generate a zendesk comment' do
    expect(server).to receive(:zendesk_comment_text).with('test.tar.gz', 'Wahoo') { 'Report output' }
    expect(ZendeskAPI::Ticket).to_not receive(:update!)

    server.update_zendesk('123', 'test.tar.gz', results: 'Wahoo', status: 0)
  end

  it 'should attempt to update the zendesk ticket' do
    server = Grese::WebhookServer.new(url: 'https://sandbox.zendesk.com')
    expect(server).to receive(:zendesk_comment_text).with('test.tar.gz', 'Wahoo') { 'Report output' }
    expect(ZendeskAPI::Ticket).to receive(:update!).with(server.zdclient, id: '123', comment: { value: 'Report output', public: false })

    server.update_zendesk('123', 'test.tar.gz', results: 'Wahoo', status: 0)
  end
end
