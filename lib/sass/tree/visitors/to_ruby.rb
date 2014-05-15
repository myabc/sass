class Sass::Tree::Visitors::ToRuby < Sass::Tree::Visitors::Base
  class << self
    def visit(root, environment = nil)
      new(environment).send(:visit, root)
    end
  end

  def visit_comment(node)
    return '' if node.invisible?
    "#{@parent_var} << ::Sass::Tree::CommentNode.resolved(" +
      "#{interp_no_strip(node.value)}, #{node.type.inspect})\n"
  end

  def visit_function(node)
    name = environment.ident_for_str(node.name, :fn)
    with_parent(nil) {"def #{name}\n#{yield}\nend"}
  end

  def visit_prop(node)
    name = environment.unique_ident
    ruby = "#{@parent_var} << #{name} = ::Sass::Tree::PropNode.resolved(#{interp(node.name)}, " +
      "#{node.value.to_ruby(@environment)})\n"
    with_parent(name) {ruby + yield}
  end

  def visit_return(node)
    "return #{node.expr.to_ruby(@environment)}"
  end

  def visit_rule(node)
    parser_var = environment.unique_ident
    ruby = "#{parser_var} = ::Sass::SCSS::StaticParser.new(#{interp(node.rule)}, '', nil, 0)\n"
    name = environment.unique_ident
    ruby << "#{@parent_var} << #{name} = ::Sass::Tree::RuleNode.resolved(" +
      "#{parser_var}.resolve_parent_refs(#{@environment_var}.selector))\n"
    with_environment do
      with_parent(name) do
        ruby << "#{@environment_var}.selector = #{name}.resolved_rules"
        ruby + yield
      end
    end
  end
end
