require 'spec_helper'

describe 'aodh::db' do
  shared_examples 'aodh::db' do
    context 'with default parameters' do
      it { should contain_class('aodh::deps') }

      it { should contain_oslo__db('aodh_config').with(
        :db_max_retries => '<SERVICE DEFAULT>',
        :connection     => 'sqlite:////var/lib/aodh/aodh.sqlite',
        :idle_timeout   => '<SERVICE DEFAULT>',
        :min_pool_size  => '<SERVICE DEFAULT>',
        :max_pool_size  => '<SERVICE DEFAULT>',
        :max_retries    => '<SERVICE DEFAULT>',
        :retry_interval => '<SERVICE DEFAULT>',
        :max_overflow   => '<SERVICE DEFAULT>',
        :pool_timeout   => '<SERVICE DEFAULT>',
      )}
    end

    context 'with specific parameters' do
      let :params do
        {
          :database_db_max_retries => '-1',
          :database_connection     => 'mysql+pymysql://aodh:aodh@localhost/aodh',
          :slave_connection        => 'mysql+pymysql://aodh:aodh@localhost2/aodh',
          :database_idle_timeout   => '3601',
          :database_min_pool_size  => '2',
          :database_max_pool_size  => '11',
          :database_max_retries    => '11',
          :database_retry_interval => '11',
          :database_max_overflow   => '21',
          :database_pool_timeout   => '21',
        }
      end

      it { should contain_class('aodh::deps') }

      it { should contain_oslo__db('aodh_config').with(
        :db_max_retries   => '-1',
        :connection       => 'mysql+pymysql://aodh:aodh@localhost/aodh',
        :slave_connection => 'mysql+pymysql://aodh:aodh@localhost2/aodh',
        :idle_timeout     => '3601',
        :min_pool_size    => '2',
        :max_pool_size    => '11',
        :max_retries      => '11',
        :retry_interval   => '11',
        :max_overflow     => '21',
        :pool_timeout     => '21',
      )}
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'aodh::db'
    end
  end
end
