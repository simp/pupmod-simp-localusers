require 'spec_helper'

describe 'localusers' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        before(:each) {
          $fh = File.new("/tmp/localusers_#{`uuidgen`.strip!}", 'w')
          $fh.puts("*.bar.baz,foo,100,100,/home/foo,foobar")
          $fh.puts("*.bar.baz,test,101,101,/home/test,testuser")
          $fh.puts('')
          $fh.close
          @tmpfile = $fh.path
        }

        context 'with default parameters' do
          it { is_expected.to contain_exec('modify_local_users').with_refreshonly(true) }
          it { is_expected.to contain_file('/usr/local/sbin/simp/localusers.rb').with_content(/### You must have a file on the server/) }
          it { is_expected.to contain_file('/usr/local/sbin/simp/localusers.rb').that_notifies('Exec[modify_local_users]') }
        end

        # context 'real_file' do
        #   before {
        #     $fh = File.new("/tmp/localusers_#{`uuidgen`.strip!}", 'w')
        #     $fh.puts("*.bar.baz,foo,100,100,/home/foo,foobar")
        #     $fh.puts("*.bar.baz,test,101,101,/home/test,testuser")
        #     $fh.puts('')
        #     $fh.close
        #     @tmpfile = $fh.path
        #   }
        #
        #   let(:params) {{ :source => @tmpfile }}
        #   let(:expected) { File.read('spec/expected/localusers_populated.rb') }
        #
        #   it { is_expected.to compile.with_all_deps }
        #   # it { require "pry";binding.pry }
        #   it {
        #     # require "pry";binding.pry
        #     is_expected.to contain_file('/usr/local/sbin/simp/localusers.rb').with_content(expected)
        #    }
        # end

        context 'with only users from hiera' do
          before {
            Puppet::Parser::Functions.newfunction(:localuser, :type => :rvalue) do |args|
              return []
            end
          }
          let(:params) {{
            :localusers => [
              '*.bar.baz,dude,1002,1002,/home/dude,dudepass',
              '*.bar.baz,otherdude,10023,10023,/home/otherdude,dudepass',
            ]
          }}
          let(:params) {{ :source => @tmpfile }}
          let(:expected) { File.read('spec/expected/localusers_populated_hiera_only.rb') }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/usr/local/sbin/simp/localusers.rb').with_content(expected) }
        end

        context 'with additional users from hiera' do
          before {
            Puppet::Parser::Functions.newfunction(:custom_function, :type => :rvalue) { |args|
                raise ArgumentError, '/tmp/' unless args[0] == 'foobar'
                ['*.bar.baz,foo,100,100,/home/foo,foobar','*.bar.baz,test,101,101,/home/test,testuser']
            }

          }
          let(:params) {{
            :localusers => [
              '*.bar.baz,dude,1002,1002,/home/dude,dudepass',
              '*.bar.baz,otherdude,10023,10023,/home/otherdude,dudepass',
            ]
          }}
          let(:expected) { File.read('spec/expected/localusers_populated_both.rb') }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/usr/local/sbin/simp/localusers.rb').with_content(expected) }
        end

      end
    end
  end
end