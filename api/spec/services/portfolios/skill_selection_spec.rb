# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/services/portfolios/skill_payload'
require_relative '../../../app/services/portfolios/coverage_lookup'
require_relative '../../../app/services/portfolios/skill_selection'

# This is the spec that guards the headline P0 from Step 3:
# "Skills never discussed still get a fabricated L1-L5 score."
RSpec.describe Portfolios::SkillSelection do
  Coverage = Struct.new(:skill_id, :skill_label, :state)

  let(:coverage_maps) do
    [
      Coverage.new('sk-eng-001', 'React / Frontend Development', 'covered'),
      Coverage.new('sk-eng-002', 'System Design', 'not_yet'),
      Coverage.new(nil, 'Micro-frontend Architecture', 'initiated')
    ]
  end

  def configured(overrides = {})
    {
      'skill_id'           => 'sk-eng-001',
      'skill_label'        => 'React / Frontend Development',
      'level'              => 3,
      'confidence'         => 'high',
      'evidence'           => ['quote'],
      'competency_summary' => 'Solid, consistent L3 behaviour.'
    }.merge(overrides)
  end

  def select(data)
    described_class.call(data, coverage_maps: coverage_maps)
  end

  it 'keeps a skill that was actually discussed' do
    result = select('configured_skills' => [configured])

    expect(result.skills.map(&:skill_id)).to eq(['sk-eng-001'])
    expect(result.skills.first.level).to eq(3)
    expect(result.skipped).to be_empty
  end

  it 'drops a skill the interview never touched, even when the model rated it' do
    result = select(
      'configured_skills' => [
        configured,
        configured('skill_id' => 'sk-eng-002', 'skill_label' => 'System Design', 'level' => 2)
      ]
    )

    expect(result.skills.map(&:skill_id)).to eq(['sk-eng-001'])
    expect(result.skipped).to contain_exactly(
      hash_including(skill_id: 'sk-eng-002', reason: :not_discussed)
    )
  end

  # The precise failure mode from Step 3: `nil.to_i.clamp(1, 5) == 1`.
  it 'never invents an L1 for a skill the model returned without a level' do
    result = select('configured_skills' => [configured('level' => nil)])

    expect(result.skills).to be_empty
    expect(result.skipped.first[:reason]).to eq(:invalid_level)
  end

  it 'keeps a discovered skill that has a coverage row' do
    result = select(
      'discovered_skills' => [
        configured('skill_id' => nil, 'skill_label' => 'Micro-frontend Architecture', 'level' => 2)
      ]
    )

    expect(result.skills.map(&:skill_label)).to eq(['Micro-frontend Architecture'])
    expect(result.skills.first).to be_discovered
  end

  it 'collapses duplicate entries for the same skill, keeping the last one' do
    result = select(
      'configured_skills' => [configured('level' => 2), configured('level' => 4)]
    )

    expect(result.skills.size).to eq(1)
    expect(result.skills.first.level).to eq(4)
  end

  it 'handles a response with neither key without raising' do
    expect(select({}).skills).to be_empty
    expect(select(nil).skills).to be_empty
  end

  it 'ignores a malformed entry instead of failing the whole generation' do
    result = select('configured_skills' => [configured, nil, 'garbage', configured('skill_label' => '')])

    expect(result.skills.size).to eq(1)
    expect(result.skipped.size).to eq(3)
  end
end
