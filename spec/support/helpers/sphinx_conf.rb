module SphinxConf
  def stub_sphinx_conf(options)
    expect(YAML).to receive(:load).
      with("test:\n  version: 2.0.3\n").
      and_return({test: options}.with_indifferent_access)

    ThinkingSphinx::Configuration.instance.reset
  end
end
